# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/errors/api_error_handling"

class PetScanApi
  include ApiErrorHandling

  def get_data(psid, update_service: nil)
    url = query_url(psid)
    response = petscan.get url
    Oj.load(response.body)
  rescue StandardError => e
    log_error(e, update_service:,
              sentry_extra: { psid:, api_url: url })
    raise e unless TYPICAL_ERRORS.include?(e.class)
    return {}
  end

  def page_titles_for_psid(psid, update_service: nil)
    titles = []
    titles_response = get_data(psid, update_service:)
    return titles if titles_response.empty?
    # Using an invalid PSID, such as a non-integer or nonexistent ID,
    # returns something like {"error":"ParseIntError { kind: InvalidDigit }"}
    # Since this is typically user error, we just treat it as 0 titles
    # and move on gracefully.
    return titles if titles_response.key? 'error'

    page_data = titles_response['*'][0]['a']['*']
    page_data.each { |page| titles << page['title'] }
    titles
  end

  ###################
  # Private methods #
  ###################
  private

  def query_url(psid)
    return "https://petscan.wmcloud.org/?psid=#{psid}&format=json"
  end

  def petscan
    conn = Faraday.new(url: 'https://petscan.wmcloud.org')
    conn.headers['User-Agent'] = ENV['dashboard_url'] + ' ' + Rails.env
    conn
  end

  TYPICAL_ERRORS = [Faraday::TimeoutError,
                    Errno::EHOSTUNREACH].freeze
end
