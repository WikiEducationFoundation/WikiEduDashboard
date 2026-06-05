# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/revision_data_parser"
require_dependency "#{Rails.root}/lib/errors/api_error_handling"

#= Fetches wiki revision data from an endpoint that provides SQL query
#= results from a replica wiki database on wmflabs:
#=   https://replica-revision-tools.wmcloud.org/
#= For what's going on at the other end, see:
#=   https://github.com/WikiEducationFoundation/WikiEduDashboardTools
class Replica # rubocop:disable Metrics/ClassLength
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
  # https://replica-revision-tools.wmcloud.org/revisions.php?lang=en&project=wikipedia&usernames[]=Ragesoss&start=20140101003430&end=20171231003430
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
  def api_get(endpoint, query = '')
    tries ||= 3
    response = do_query(endpoint, query)
    parsed = parse_replica_body(response.body)
    return parsed['data'] if parsed && parsed['success']
    return skip_replica_failure(endpoint, parsed) if replica_connection_failure?(parsed)
    raise "Replica #{endpoint} request failed (HTTP #{response.code})"
  rescue StandardError => e
    tries -= 1
    sleep 2 && retry unless tries.zero?
    log_error(e, update_service: @update_service,
              sentry_extra: { endpoint:, query:,
                              language: @wiki.language, project: @wiki.project })
  end

  def api_post(endpoint, key, data)
    tries ||= 3
    response = do_post(endpoint, key, data)
    return if response.code == '200' && response.body.empty?
    parsed = parse_replica_body(response.body)
    return parsed['data'] if parsed && parsed['success']
    return skip_replica_failure(endpoint, parsed) if replica_connection_failure?(parsed)
    raise "Replica #{endpoint} request failed (HTTP #{response.code})"
  rescue StandardError => e
    tries -= 1
    sleep 2 && retry unless tries.zero?
    log_error(e, update_service: @update_service,
              sentry_extra: { query: data,
                              response_body: response&.body,
                              language: @wiki.language,
                              project: @wiki.project })
  end

  # Parse a replica response body into a Hash, or nil when there is no parseable
  # JSON (an empty body, an HTML error page, etc.).
  def parse_replica_body(body)
    return nil if body.blank?
    Oj.load(body)
  rescue Oj::ParseError
    nil
  end

  # A replica DB *connection* failure, as opposed to a query-level failure.
  # As of WikiEduDashboardTools PR #22 these return HTTP 502 with a JSON body
  # carrying an "error" message — e.g. a newly created wiki whose wikireplica
  # views don't exist yet (see Wikimedia T415977). It is a known, non-transient
  # per-wiki condition, so we skip the wiki rather than retrying and reporting
  # every call to Sentry. Query-level failures ({ "success": false } with no
  # "error" key) still fall through to the hard-error path so they stay visible.
  def replica_connection_failure?(parsed)
    parsed.is_a?(Hash) && parsed['success'] == false && parsed['error'].present?
  end

  def skip_replica_failure(endpoint, parsed)
    Rails.logger.warn(
      "Replica #{endpoint} cannot reach #{@wiki.language}.#{@wiki.project}: " \
      "#{parsed['error']} — skipping this wiki for this update cycle"
    )
    nil
  end

  # Finite timeouts on the Replica HTTP call: without them, a silent server
  # leaves the worker blocked in IO#wait_readable forever (holding its
  # sidekiq-unique-jobs lock for up to 30 days). api_get's rescue loop will
  # retry on Net::ReadTimeout / Net::OpenTimeout via StandardError.
  OPEN_TIMEOUT = 30
  READ_TIMEOUT = 180

  def do_query(endpoint, query)
    url = URI.parse compile_query_url(endpoint, query)
    req = Net::HTTP::Get.new(url)
    req.add_field('User-Agent', ENV['user_agent'])
    Net::HTTP.start(url.host, url.port, use_ssl: true, open_timeout: OPEN_TIMEOUT,
                    read_timeout: READ_TIMEOUT) { |http| http.request(req) }
  end

  REPLICA_TOOL_URL = 'https://replica-revision-tools.wmcloud.org/'

  def do_post(endpoint, key, data)
    url = URI.parse "#{REPLICA_TOOL_URL}#{endpoint}"
    database_params = project_database_params_post
    form_data = { 'db' => database_params['db'],
                  'lang' => database_params['lang'],
                  'project' => database_params['project'],
                   key => data }

    req = Net::HTTP::Post.new(url.path)
    req.add_field('User-Agent', ENV['user_agent'])
    req.content_type = 'application/x-www-form-urlencoded'
    req.body = URI.encode_www_form(form_data)

    Net::HTTP.start(url.host, url.port, use_ssl: true, open_timeout: OPEN_TIMEOUT,
                    read_timeout: READ_TIMEOUT) { |http| http.request(req) }
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
  # Or check the table here: https://db-names.toolforge.org/
  #
  # Here are some of the naming exceptions that we must special-case:
  SPECIAL_DB_NAMES = { 'www.wikidata.org' => 'wikidatawiki',
                       'wikisource.org' => 'sourceswiki',
                       'incubator.wikimedia.org' => 'incubatorwiki',
                       'commons.wikimedia.org' => 'commonswiki',
                       'meta.wikimedia.org' => 'metawiki' }.freeze
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
