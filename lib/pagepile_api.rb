# frozen_string_literal: true
class PagePileApi
  def get_data(pileid)
    response = pagepile.get query_url(pileid)
    title_data = Oj.load(response.body)
    title_data
  rescue StandardError => e
    raise e unless Errno::EHOSTUNREACH.include?(e.class)
    return {}
  end

  def get_wiki(pileid)
    wiki_data = get_data(pileid)
    return nil if wiki_data.empty?
    wiki_data['wiki']
  end

  def page_titles_for_pileid(pileid)
    titles_response = get_data(pileid)
    return [] if titles_response.empty?
    titles = titles_response['pages']
    titles
  end

  ###################
  # Private methods #
  ###################
  private

  def query_url(pileid)
    return "https://tools.wmflabs.org/pagepile/api.php?id=#{pileid}&action=get_data&format=json"
  end

  def pagepile
    conn = Faraday.new(url: 'https://tools.wmflabs.org/pagepile')
    conn.headers['User-Agent'] = ENV['dashboard_url'] + ' ' + Rails.env
    conn
  end
end
