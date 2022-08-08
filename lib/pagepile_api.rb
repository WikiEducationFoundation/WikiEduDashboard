# frozen_string_literal: true
class PagePileApi
  def initialize(category)
    raise 'Wrong category type' unless category.source == 'pileid'
    @category = category
    @wiki = @category.wiki
  end

  def page_titles_for_pileid
    fetch_pile_data
    return [] if @pile_data.empty?

    update_language_and_project

    titles = @pile_data['pages']
    titles
  end

  ###################
  # Private methods #
  ###################
  private

  def pileid
    @category.name
  end

  def fetch_pile_data
    response = pagepile.get query_url
    @pile_data = Oj.load(response.body)
  rescue StandardError => e
    Sentry.capture_exception e
    @pile_data = {}
  end

  # This ensures the Category has the same wiki as the PagePile.
  def update_language_and_project
    language = @pile_data['language']
    project = @pile_data['project']
    return if [@wiki.language, @wiki.project] == [language, project]

    @wiki = Wiki.get_or_create(language:, project:)
    @category.update(wiki: @wiki)
  end

  def query_url
    return "https://pagepile.toolforge.org/api.php?id=#{pileid}&action=get_data&format=json"
  end

  def pagepile
    conn = Faraday.new(url: 'https://pagepile.toolforge.org')
    conn.headers['User-Agent'] = ENV['dashboard_url'] + ' ' + Rails.env
    conn
  end
end
