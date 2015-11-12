# Fetches pageview data from the Wikimedia pageviews REST API
# Documentation: https://wikimedia.org/api/rest_v1/?doc#!/Pageviews_data/get_metrics_pageviews_per_article_project_access_agent_article_granularity_start_end
class WikiPageviews
  ################
  # Entry points #
  ################

  def self.average_views_for_article(title, language=nil)
    language = ENV['wiki_language'] if language.nil?
    data = recent_views(title, language)
    return unless data
    data = Utils.parse_json(data)
    return unless data.include?('items')
    daily_view_data = data['items']
    days = daily_view_data.count
    total_views = 0
    daily_view_data.each do |day_data|
      total_views += day_data['views']
    end
    average_views = total_views.to_f / days
    average_views
  end

  ##################
  # Helper methods #
  ##################
  def self.recent_views(title, language)
    title = URI.escape(title)
    base_url = "https://wikimedia.org/api/rest_v1/metrics/pageviews/per-article/#{language}.wikipedia/all-access/user/"
    # TODO: make this pick a recent month, or recent two months.
    url = base_url + "#{title}/daily/2015100100/2015103000"
    api_get url
  end

  ###################
  # Private methods #
  ###################
  class << self
    private

    def api_get(url)
      tries ||= 3
      Net::HTTP::get(URI.parse(url))
    rescue Errno::ETIMEDOUT
      Rails.logger.error I18n.t('timeout', api: 'wikimedia.org/api/rest_v1', tries: (tries -= 1))
      retry unless tries.zero?
    rescue StandardError => e
      Rails.logger.error "Wikimedia REST API error: #{e}"
      Raven.capture_exception e
    end
  end
end
