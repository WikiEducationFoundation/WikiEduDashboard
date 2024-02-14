# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/revision_data_parser"
require_dependency "#{Rails.root}/lib/errors/api_error_handling"

#= Fetches wiki revision data from an endpoint that provides SQL query
#= results from a replica wiki database on wmflabs:
#=   https://dashboard-replica-endpoint.wmcloud.org/
#= For what's going on at the other end, see:
#=   https://github.com/WikiEducationFoundation/WikiEduDashboardTools
class Replica
  include ApiErrorHandling

  def initialize(wiki, update_service = nil)
    @wiki = wiki
    @update_service = update_service
  end

  # This is the maximum number of concurrent queries the system should run
  # against the wmflabs replica endpoint.
  CONCURRENCY_LIMIT = 2

  ################
  # Entry points #
  ################

  # Given a list of users and a start and end date, return a nicely formatted
  # hash of page_ids and revisions made by those users between those dates.
  def get_revisions(users, rev_start, rev_end)
    raw = get_revisions_raw(users, rev_start, rev_end)
    @data = {}
    return @data unless raw.is_a?(Enumerable)
    raw.each { |revision| extract_revision_data(revision) }

    @data
  end

  # Given a list of users and a start and end date, get data about revisions
  # those users made between those dates.
  # As of 2015-02-24, revisions.php only queries namespaces:
  #   0 ([mainspace])
  #   2 (User:)
  def get_revisions_raw(users, rev_start, rev_end)
    user_list = compile_usernames_query(users)
    oauth_tags = compile_oauth_tags
    oauth_tags = oauth_tags.blank? ? oauth_tags : "&#{oauth_tags}"
    query = user_list + oauth_tags + "&start=#{rev_start}&end=#{rev_end}"
    api_get('revisions.php', query)
  end

  # Given a list of articles *or* hashes of the form { 'mw_page_id' => 1234 },
  # see which ones have not been deleted.
  def get_existing_articles_by_id(articles)
    article_list = compile_article_ids_query(articles)
    api_get('articles.php', article_list)
  end

  # Given a list of articles *or* hashes of the form { 'title' => 'Something' },
  # see which ones have not been deleted.
  def post_existing_articles_by_title(articles)
    article_list = articles.map { |article| article['title'] }
    api_post('articles.php', 'post_article_titles[]', article_list)
  end

  # Given a list of revisions, see which ones have not been deleted
  def get_existing_revisions_by_id(revisions)
    revision_list = compile_revision_ids_query(revisions)
    api_get('revisions.php', revision_list)
  end

  ###################
  # Private methods #
  ###################

  private

  ###################
  # Parsing methods #
  ###################

  def extract_revision_data(revision)
    parsed = RevisionDataParser.new(@wiki).parse_revision(revision)
    page_id = parsed['article']['mw_page_id']
    unless @data.include?(page_id)
      @data[page_id] = {}
      @data[page_id]['article'] = parsed['article']
      @data[page_id]['revisions'] = []
    end
    @data[page_id]['revisions'].push parsed['revision']
  end

  ###############
  # API methods #
  ###############

  # Given an endpoint ('articles.php' or 'revisions.php') and a
  # query appropriate to that endpoint, return the parsed json response.
  #
  # Example revisions.php query:
  #   https://dashboard-replica-endpoint.wmcloud.org//revisions.php?lang=en&project=wikipedia&usernames[]=Ragesoss&start=20140101003430&end=20171231003430
  #
  # Example revisions.php parsed response:
  # [{"page_id"=>"44962463",
  #   "page_title"=>"Swarfe/ENGL-122-2014",
  #   "page_namespace"=>"2",
  #   "rev_id"=>"641297913",
  #   "rev_timestamp"=>"20150106205746",
  #   "rev_user_text"=>"Sage (Wiki Ed)",
  #   "rev_user"=>"21515199",
  #   "new_article"=>"false",
  #   "byte_change"=>"38"},
  #  {"page_id"=>"44962463",
  #   "page_title"=>"Swarfe/ENGL-122-2014",
  #   "page_namespace"=>"2",
  #   "rev_id"=>"641298113",
  #   "rev_timestamp"=>"20150106205902",
  #   "rev_user_text"=>"Sage (Wiki Ed)",
  #   "rev_user"=>"21515199",
  #   "new_article"=>"false",
  #   "byte_change"=>"-50"
  #  }]
  def api_get(endpoint, query='')
    tries ||= 3
    response = do_query(endpoint, query)
    raise unless response.code == '200'
    response_body = response.body
    parsed = Oj.load(response_body)
    raise unless parsed['success']
    parsed['data']
  rescue StandardError => e
    tries -= 1
    sleep 2 && retry unless tries.zero?
    log_error(e, update_service: @update_service,
              sentry_extra: { endpoint:, query:,
                              language: @wiki.language, project: @wiki.project })
  end

  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/PerceivedComplexity
  def api_post(endpoint, key, data)
    tries ||= 3
    response = do_post(endpoint, key, data)
    raise unless response.code == '200'
    return if response.body.empty?
    parsed = Oj.load(response.body)
    raise unless parsed['success']
    parsed['data']
  rescue StandardError => e
    tries -= 1
    sleep 2 && retry unless tries.zero?
    log_error(e, update_service: @update_service,
              sentry_extra: { query: data,
                              response_body: response&.body,
                              language: @wiki.language,
                              project: @wiki.project })
  end
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/PerceivedComplexity

  def do_query(endpoint, query)
    url = compile_query_url(endpoint, query)
    Net::HTTP::get_response(URI.parse(url))
  end

  REPLICA_TOOL_URL = 'https://dashboard-replica-endpoint.wmcloud.org/'

  def do_post(endpoint, key, data)
    url = "#{REPLICA_TOOL_URL}#{endpoint}"
    database_params = project_database_params_post
    Net::HTTP::post_form(URI.parse(url),
                         'db' => database_params['db'],
                         'lang' => database_params['lang'],
                         'project' => database_params['project'],
                         key => data)
  end

  # Query URL for the WikiEduDashboardTools repository
  def compile_query_url(endpoint, query)
    "#{REPLICA_TOOL_URL}#{endpoint}?#{project_database_params}&#{query}"
  end

  ###############################
  # Replica database parameters #
  ###############################

  # The dashboard replica endpoint tool connects to a replica database for whatever
  # wiki is being queried. Normally the database names can be derived directly
  # from the language code and project — and this happens at the toolforge
  # end of things — but some wikis don't follow the simple normal convention.
  #
  # For languages with hyphens in the language code, they are usually replaced
  # with underscores.
  #
  # See https://quarry.wmflabs.org/query/4031 to look up database name for a wiki
  #
  # Here are some of the naming exceptions that we must special-case:
  SPECIAL_DB_NAMES = { 'www.wikidata.org' => 'wikidatawiki',
                       'wikisource.org' => 'sourceswiki',
                       'incubator.wikimedia.org' => 'incubatorwiki',
                       'commons.wikimedia.org' => 'commonswiki' }.freeze
  def project_database_params
    # Use special-case db param if available.
    return "db=#{SPECIAL_DB_NAMES[@wiki.domain]}" if SPECIAL_DB_NAMES[@wiki.domain]
    # Otherwise, uses the language and project, and replica API infers the standard db name.
    "lang=#{@wiki.language.tr('-', '_')}&project=#{@wiki.project}"
  end

  def project_database_params_post
    db = ''
    db = SPECIAL_DB_NAMES[@wiki.domain] if SPECIAL_DB_NAMES[@wiki.domain]
    { 'db' => db, 'lang' => @wiki.language&.tr('-', '_'), 'project' => @wiki.project }
  end

  def compile_usernames_query(users)
    { usernames: users.map(&:username) }.to_query
  end

  def compile_oauth_tags
    oauth_ids = ENV['oauth_ids']
    return '' if oauth_ids.nil?
    oauth_id_tags = oauth_ids.split(',').map { |id| "OAuth CID: #{id}" }
    { oauth_tags: oauth_id_tags }.to_query
  end

  # Compile an article list to send to the replica endpoint, which might look
  # something like this:
  # "article_ids[]=100&article_ids[]=300"
  def compile_article_ids_query(articles)
    article_page_ids = articles.map { |article| article['mw_page_id'] }
    { article_ids: article_page_ids }.to_query
  end

  def compile_revision_ids_query(revisions)
    { revision_ids: revisions.map(&:mw_rev_id) }.to_query
  end

  # These are typical network errors that we expect to encounter.
  TYPICAL_ERRORS = [Errno::ETIMEDOUT, Net::ReadTimeout, Errno::ECONNREFUSED,
                    Oj::ParseError].freeze
end
