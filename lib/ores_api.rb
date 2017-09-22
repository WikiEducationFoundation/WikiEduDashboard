# frozen_string_literal: true

# Gets data from ORES — Objective Revision Evaluation Service
# https://meta.wikimedia.org/wiki/Objective_Revision_Evaluation_Service
class OresApi
  # This is the maximum number of concurrent requests the app should make.
  # The ORES team suggested this as a safe number in ~2016.
  CONCURRENCY = 50

  def initialize(wiki)
    raise InvalidProjectError unless wiki.project == 'wikipedia'
    @project_code = wiki.language + 'wiki'
  end

  def get_revision_data(rev_id)
    # TODO: i18n
    response = ores_server.get query_url(rev_id)
    ores_data = JSON.parse(response.body)
    ores_data
  rescue StandardError => error
    raise error unless TYPICAL_ERRORS.include?(error.class)
    return {}
  end

  TYPICAL_ERRORS = [
    Errno::ETIMEDOUT,
    Net::ReadTimeout,
    Errno::ECONNREFUSED,
    JSON::ParserError,
    Errno::EHOSTUNREACH,
    Faraday::ConnectionFailed,
    Faraday::TimeoutError
  ].freeze

  class InvalidProjectError < StandardError
  end

  private

  def query_url(rev_id)
    base_url = "/v2/scores/#{@project_code}/wp10/"
    url = base_url + rev_id.to_s + '/?features'
    url = URI.encode url
    url
  end

  def ores_server
    conn = Faraday.new(url: 'https://ores.wikimedia.org')
    conn.headers['User-Agent'] = ENV['dashboard_url'] + ' ' + Rails.env
    conn
  end
end
