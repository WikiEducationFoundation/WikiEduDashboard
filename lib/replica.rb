# frozen_string_literal: true

require "#{Rails.root}/lib/revision_data_parser"

#= Fetches wiki revision data from an endpoint that provides SQL query
#= results from a replica wiki database on wmflabs:
#=   https://tools.wmflabs.org/wikiedudashboard
#= For what's going on at the other end, see:
#=   https://github.com/WikiEducationFoundation/WikiEduDashboardTools
class Replica
  def initialize(wiki)
    @wiki = wiki
  end

  # This is the maximum number of concurrent queries the system should run
  # against the wmflabs replica endpoint.
  CONCURRENCY_LIMIT = 10

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
  def get_existing_articles_by_title(articles)
    article_list = compile_article_titles_query(articles)
    api_get('articles.php', article_list)
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
  #   https://tools.wmflabs.org/wikiedudashboard/revisions.php?lang=en&project=wikipedia&usernames[]=Ragesoss&start=20140101003430&end=20171231003430
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
    return if response.empty?
    parsed = JSON.parse response.to_s
    return unless parsed['success']
    parsed['data']
  rescue StandardError => e
    tries -= 1
    sleep 2 && retry unless tries.zero?

    report_exception e, endpoint, query
  end

  def do_query(endpoint, query)
    url = compile_query_url(endpoint, query)
    Net::HTTP::get(URI.parse(url))
  end

  # Query URL for the WikiEduDashboardTools repository
  def compile_query_url(endpoint, query)
    base_url = 'https://tools.wmflabs.org/wikiedudashboard/'
    "#{base_url}#{endpoint}?#{project_database_params}&#{query}"
  end

  SPECIAL_DB_NAMES = { 'www.wikidata.org' => 'wikidatawiki',
                       'wikisource.org' => 'sourceswiki',
                       'incubator.wikimedia.org' => 'incubatorwiki' }.freeze
  def project_database_params
    # Returns special Labs database names as parameters for databases not meeting
    # project/language naming conventions
    return "db=#{SPECIAL_DB_NAMES[@wiki.domain]}" if SPECIAL_DB_NAMES[@wiki.domain]
    # Otherwise, uses the language and project, and replica API infers the standard db name.
    "lang=#{@wiki.language}&project=#{@wiki.project}"
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
  # "article_ids[]='Artist'&article_ids[]='Microsoft_Research'"
  def compile_article_titles_query(articles)
    quoted_titles = articles.map { |article| "'#{CGI.escape(article['title'])}'" }
    { article_titles: quoted_titles }.to_query
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
                    JSON::ParserError].freeze
  def report_exception(error, endpoint, query, level='error')
    Rails.logger.error "replica.rb #{endpoint} query failed after 3 tries: #{error}"
    level = 'warning' if TYPICAL_ERRORS.include?(error.class)
    Raven.capture_exception error, level: level, extra: {
      query: query, endpoint: endpoint, language: @wiki.language, project: @wiki.project
    }
    return nil
  end
end
