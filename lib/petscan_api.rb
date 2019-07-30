# frozen_string_literal: true
class PetScanApi
  def get_titles(psid)
    response = petscan.get query_url(psid)
    title_data = Oj.load(response.body)
    title_data
  rescue StandardError => e
    raise e unless Errno::EHOSTUNREACH.include?(e.class)
    return {}
  end

  def page_titles_for_psid(psid)
    titles = []
    titles_response = get_titles(psid)
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
end
