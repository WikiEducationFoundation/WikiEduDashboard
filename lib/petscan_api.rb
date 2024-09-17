# frozen_string_literal: true
class PetScanApi
  def get_data(psid)
    response = petscan.get query_url(psid)
    Oj.load(response.body)
  rescue StandardError => e
    raise e unless typical_errors.include?(e.class)
    return {}
  end

  def page_titles_for_psid(psid)
    titles = []
    titles_response = get_data(psid)
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
    return "https://petscan.wmflabs.org/?psid=#{psid}&format=json"
  end

  def petscan
    conn = Faraday.new(url: 'https://petscan.wmflabs.org')
    conn.headers['User-Agent'] = ENV['dashboard_url'] + ' ' + Rails.env
    conn
  end

  def typical_errors
    [Errno::EHOSTUNREACH, Faraday::TimeoutError]
  end
end
