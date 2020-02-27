# frozen_string_literal: true
class PetScanApi
  def get_data(psid)
    response = petscan.get query_url(psid)
    title_data = Oj.load(response.body)
    title_data
  rescue StandardError => e
    raise e unless typical_errors.include?(e.class)
    return {}
  end

  def get_articleid(psid)
    articles_id = []
    page_data = get_data(psid)
    return articles_id if page_data.empty?

    articles_data = page_data['*'][0]['a']['*']
    articles_data.each { |article| articles_id << article['id'] }
    articles_id
  end

  def page_titles_for_psid(psid)
    titles = []
    titles_response = get_data(psid)
    return titles if titles_response.empty?

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
    [Errno::EHOSTUNREACH]
  end
end
