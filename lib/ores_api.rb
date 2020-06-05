# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/errors/error_handling"

# Gets data from ORES — Objective Revision Evaluation Service
# https://meta.wikimedia.org/wiki/Objective_Revision_Evaluation_Service
class OresApi
  include ErrorHandling

  # This is the maximum number of concurrent requests the app should make.
  # As of 2018-09-19, ORES policy is a max of 4 parallel connections per IP:
  # https://lists.wikimedia.org/pipermail/wikitech-l/2018-September/090835.html
  # Use this if we need to make parallel threaded requests.
  # CONCURRENCY = 4

  ORES_SERVER_URL = 'https://ores.wikimedia.org'
  REVS_PER_REQUEST = 50

  # All the wikis with an articlequality model as of 2018-09-18
  # https://ores.wikimedia.org/v3/scores/
  AVAILABLE_WIKIPEDIAS = %w[en eu fa fr ru simple tr].freeze

  def self.valid_wiki?(wiki)
    return true if wiki.project == 'wikidata'
    wiki.project == 'wikipedia' && AVAILABLE_WIKIPEDIAS.include?(wiki.language)
  end

  def initialize(wiki, course = nil)
    raise InvalidProjectError unless OresApi.valid_wiki?(wiki)
    @project_code = wiki.project == 'wikidata' ? 'wikidata' + 'wiki' : wiki.language + 'wiki'
    @project_model = wiki.project == 'wikidata' ? 'itemquality' : 'articlequality'
    @course = course
  end

  def get_revision_data(rev_ids)
    url_query = query_url(rev_ids)
    response = ores_server.get(url_query)
    response_body = response.body
    ores_data = Oj.load(response_body)
    ores_data
  rescue StandardError => e
    url = ORES_SERVER_URL + url_query
    invoke_error_handling(e, url, response_body)
    raise e unless TYPICAL_ERRORS.include?(e.class)
    return {}
  end

  TYPICAL_ERRORS = [
    Errno::ETIMEDOUT,
    Net::ReadTimeout,
    Errno::ECONNREFUSED,
    Oj::ParseError,
    Errno::EHOSTUNREACH,
    Faraday::ConnectionFailed,
    Faraday::TimeoutError
  ].freeze

  class InvalidProjectError < StandardError
  end

  private

  def query_url(rev_ids)
    base_url = "/v3/scores/#{@project_code}/?models=#{@project_model}&features&revids="
    url = base_url + rev_ids.join('|')
    url
  end

  def ores_server
    conn = Faraday.new(url: ORES_SERVER_URL)
    conn.headers['User-Agent'] = ENV['dashboard_url'] + ' ' + Rails.env
    conn
  end

  def invoke_error_handling(error, url, response_body)
    extra = { project_code: @project_code, project_model: @project_model, url: url }
    optional_params = build_optional_params(@course, error, url, response_body)
    perform_error_handling(error, TYPICAL_ERRORS, extra, @course, optional_params)
  end
end
