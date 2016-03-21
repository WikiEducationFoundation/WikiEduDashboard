# Fetches pageview data from the Wikimedia pageviews REST API
# Documentation: https://wikimedia.org/api/rest_v1/?doc#!/Pageviews_data/get_metrics_pageviews_per_article_project_access_agent_article_granularity_start_end
class WikiPageviews
  def initialize(article)
    @article = article
    @title = article.title
    @wiki = article.wiki
  end
  ################
  # Entry points #
  ################
  # EARLIEST_PAGEVIEWS_AVAILABLE = '2015-08-01'
  # As of 2016-01-27, data is only available back to 2015-08-01.
  # Eventually, this should be backfilled to 2015-05-01, but not earlier.
  # If the requested range includes dates with no data, then only the view data
  # for available dates will be returned, potentially undercounting the actual
  # number of views. For the most part, we don't request view data from before
  # it becomes available. The exception is when old pages get moved into
  # mainspace.

  # Given an article title and a date, return the number of page views for every
  # day from that date until today.
  #
  # [title]  title of a Wikipedia page (including namespace prefix, if applicable)
  def views_for_article(opts = {})
    start_date = opts[:start_date] || 1.month.ago

    end_date = opts[:end_date] || Time.zone.today
    url = query_url(start_date: start_date, end_date: end_date)
    data = api_get url
    return unless data
    data = Utils.parse_json(data)
    return unless data.include?('items')
    daily_view_data = data['items']
    views = {}
    daily_view_data.each do |day_data|
      date = day_data['timestamp'][0..7]
      views[date] = day_data['views']
    end
    views
  end

  def average_views
    data = recent_views
    # TODO: better handling of unexpected or empty responses, including logging
    return unless data
    data = Utils.parse_json(data)
    return unless data.include?('items')
    daily_view_data = data['items']
    days = daily_view_data.count
    total_views = 0
    daily_view_data.each do |day_data|
      total_views += day_data['views']
    end
    return if total_views == 0
    average_views = total_views.to_f / days
    average_views
  end

  ##################
  # Helper methods #
  ##################
  def recent_views
    start_date = 50.days.ago
    end_date = 1.day.ago
    url = query_url(start_date: start_date, end_date: end_date)
    api_get url
  end

  def query_url(start_date:, end_date:)
    title = CGI.escape(@title)
    base_url = 'https://wikimedia.org/api/rest_v1/metrics/pageviews/'
    configuration_params = "per-article/#{@wiki.language}.#{@wiki.project}/all-access/user/"
    start_param = start_date.strftime('%Y%m%d')
    end_param = end_date.strftime('%Y%m%d')
    title_and_date_params = "#{title}/daily/#{start_param}00/#{end_param}00"
    url = base_url + configuration_params + title_and_date_params
    url
  end

  ###################
  # Private methods #
  ###################
  private

  def api_get(url)
    tries ||= 3
    response = Net::HTTP::get(URI.parse(url))
    response
  rescue Errno::ETIMEDOUT, Errno::ENETUNREACH, SocketError
    Rails.logger.error I18n.t('timeout', api: 'wikimedia.org/api/rest_v1', tries: (tries -= 1))
    retry unless tries.zero?
  rescue StandardError => e
    Rails.logger.error "Wikimedia REST API error: #{e}"
    raise e
  end
end
