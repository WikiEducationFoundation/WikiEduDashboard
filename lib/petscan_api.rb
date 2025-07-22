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
    raise e
  end

  def page_titles_for_psid(psid, update_service: nil)
    titles = []
    titles_response = get_data(psid, update_service:)
    return titles if titles_response.empty?
    # Petscan query errors (such as invalid PSID but also server bugs) often return responses like:
    # {"error":"some error message"}.
    # We don't want to fail gracefully in these cases, as we risk
    # emptying a category that was previously updated correctly.
    raise PetscanResponseError if titles_response.key? 'error'

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
    conn.options.timeout = TIMEOUT
    conn.headers['User-Agent'] = ENV['dashboard_url'] + ' ' + Rails.env
    conn
  end

  TYPICAL_ERRORS = [Errno::EHOSTUNREACH].freeze

  # The petscan request may take more than default timeout to complete so we set it to 4 minutes
  TIMEOUT = 240

  class PetscanResponseError < StandardError; end
end
