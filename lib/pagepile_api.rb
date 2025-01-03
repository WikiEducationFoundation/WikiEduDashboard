# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/errors/api_error_handling"

class PagePileApi
  include ApiErrorHandling

  def initialize(category)
    raise 'Wrong category type' unless category.source == 'pileid'
    @category = category
    @wiki = @category.wiki
  end

  def page_titles_for_pileid(update_service: nil)
    fetch_pile_data(update_service:)
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

  def fetch_pile_data(update_service: nil)
    response = pagepile.get query_url
    @pile_data = Oj.load(response.body)
    url = query_url
  rescue StandardError => e
    log_error(e, update_service:,
              sentry_extra: { api_url: url })
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
    conn.headers['User-Agent'] = "#{ENV['dashboard_url']} #{Rails.env}"
    conn
  end

  TYPICAL_ERRORS = [Faraday::TimeoutError,
                    Faraday::ConnectionFailed].freeze
end
