# frozen_string_literal: true
class PetScanApi
  def get_titles(psid)
    response = petscan.get query_url(psid)
    title_data = Oj.load(response.body)
    title_data
  rescue StandardError => e
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

  ###################
  # Private methods #
  ###################
  private

  def query_url(psid)
    base_url = "https://petscan.wmflabs.org/?psid=#{psid}&format=json"
    base_url
  end

  def petscan
    conn = Faraday.new(url: 'https://petscan.wmflabs.org')
    conn.headers['User-Agent'] = ENV['dashboard_url'] + ' ' + Rails.env
    conn
  end
end
