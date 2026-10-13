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
  # The external revisions.php API queries a predefined set of content and talk namespaces
  # (e.g., 0, 1, 2, 3, 118, etc.) which varies by project.
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
    handle_replica_response(endpoint, response)
  rescue StandardError => e
    tries -= 1
    retry if back_off_if_rate_limited(e, tries)
    sleep 2 && retry unless tries.zero?
    report_failure(e, { endpoint:, query:, language: @wiki.language, project: @wiki.project })
  end

  # Returns the response data, skips a known per-wiki failure, or raises.
  def handle_replica_response(endpoint, response)
    parsed = parse_replica_body(response.body)
    return parsed['data'] if parsed && parsed['success']
    return skip_replica_failure(endpoint, parsed) if replica_connection_failure?(parsed)
    raise RateLimitedError, response if response.code == '429'
    raise "Replica #{endpoint} request failed (HTTP #{response.code})"
  end

  # On a 429, back off and return true to retry, or raise once out of tries,
  # so callers stop instead of treating the fetch as "no revisions" (PEONY-392).
  def back_off_if_rate_limited(error, tries_left)
    return false unless error.is_a?(RateLimitedError)
    @update_service&.record_too_many_requests
    raise error if tries_left.zero?
    sleep retry_delay_for(error)
    true
  end

  # Honor Retry-After, else wait a few seconds. Capped low since this blocks a Sidekiq thread.
  DEFAULT_RETRY_AFTER_SECONDS = 5
  MAX_RETRY_AFTER_SECONDS = 30
  # Keeps many rate-limited updates from retrying at the same moment.
  MAX_RETRY_JITTER_SECONDS = 1.0

  def retry_delay_for(error)
    base = (error.retry_after_seconds || DEFAULT_RETRY_AFTER_SECONDS)
           .clamp(0, MAX_RETRY_AFTER_SECONDS)
    base + retry_jitter
  end

  def retry_jitter
    rand(0.0..MAX_RETRY_JITTER_SECONDS)
  end

  def api_post(endpoint, key, data)
    tries ||= 3
    response = do_post(endpoint, key, data)
    return if response.code == '200' && response.body.empty?
    handle_replica_response(endpoint, response)
  rescue StandardError => e
    tries -= 1
    retry if back_off_if_rate_limited(e, tries)
    sleep 2 && retry unless tries.zero?
    report_failure(e, post_error_extra(data, response))
  end

  # Within one update, only the first failure of each kind goes to Sentry; repeats
  # are only counted. Returns nil, like log_error.
  def report_failure(error, sentry_extra)
    if repeat_failure_in_this_update?(error)
      @update_service.update_error_stats
      Rails.logger.info "Replica failure already reported this update: #{error}"
      return nil
    end
    log_error(error, update_service: @update_service, sentry_extra:)
  end

  def repeat_failure_in_this_update?(error)
    return false unless @update_service.respond_to?(:first_replica_failure?)
    !@update_service.first_replica_failure?("#{error.class}: #{error.message}")
  end

  def post_error_extra(data, response)
    { query: data, response_body: response&.body,
      language: @wiki.language, project: @wiki.project }
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

  # Replica failures that should stop a course update. Callers rescue this base
  # class; currently only RateLimitedError is raised.
  class RequestFailedError < StandardError
    attr_reader :status, :response_body

    def initialize(response, message = nil)
      @status = response.code.to_i
      @response_body = response.body
      super(message || "Replica request failed (HTTP #{@status})")
    end

    def retry_after_seconds
      nil
    end
  end

  # Raised when Replica responds 429 (see PEONY-392).
  class RateLimitedError < RequestFailedError
    attr_reader :retry_after_seconds

    def initialize(response)
      @retry_after_seconds = parse_retry_after(response['Retry-After'])
      super(response, "Replica rate limited (HTTP #{response.code})")
    end

    private

    # Retry-After is seconds here (no evidence of the HTTP-date form).
    def parse_retry_after(value)
      return nil if value.nil?
      Integer(value, exception: false)
    end
  end

  # These are typical network errors that we expect to encounter.
  TYPICAL_ERRORS = [Errno::ETIMEDOUT, Net::ReadTimeout, Errno::ECONNREFUSED,
                    Oj::ParseError].freeze
end
