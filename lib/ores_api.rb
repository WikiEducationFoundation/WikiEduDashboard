# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/errors/course_error_records"

# Gets data from ORES — Objective Revision Evaluation Service
# https://meta.wikimedia.org/wiki/Objective_Revision_Evaluation_Service
class OresApi
  include Errors::CourseErrorRecords

  # This is the maximum number of concurrent requests the app should make.
  # As of 2018-09-19, ORES policy is a max of 4 parallel connections per IP:
  # https://lists.wikimedia.org/pipermail/wikitech-l/2018-September/090835.html
  # Use this if we need to make parallel threaded requests.
  # CONCURRENCY = 4

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
    server_conn = ores_server
    url_prefix = server_conn.url_prefix
    url_query = query_url(rev_ids)
    response = server_conn.get(url_query)
    ores_data = Oj.load(response.body)
    ores_data
  rescue StandardError => e
    save_course_error_record(@course, e.class, (url_prefix + url_query).to_s)
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
    conn = Faraday.new(url: 'https://ores.wikimedia.org')
    conn.headers['User-Agent'] = ENV['dashboard_url'] + ' ' + Rails.env
    conn
  end
end
