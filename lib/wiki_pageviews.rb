# frozen_string_literal: true

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
    daily_view_data = fetch_view_data(start_date, end_date)
    return unless daily_view_data

    views = {}
    daily_view_data.each do |day_data|
      date = day_data['timestamp'][0..7]
      views[date] = day_data['views']
    end
    views
  end

  def average_views
    daily_view_data = recent_views
    average_views = calculate_average_views(daily_view_data)
    average_views
  end

  ##################
  # Helper methods #
  ##################
  private

  def recent_views
    start_date = 50.days.ago
    end_date = 1.day.ago
    url = query_url(start_date: start_date, end_date: end_date)
    parse_results(api_get(url))
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

  def fetch_view_data(start_date, end_date)
    url = query_url(start_date: start_date, end_date: end_date)
    data = api_get url
    parse_results(data)
  end

  def calculate_average_views(daily_view_data)
    days = daily_view_data.count
    total_views = 0

    daily_view_data.each do |day_data|
      total_views += day_data['views']
    end

    return 0 if total_views.zero?
    average_views = total_views.to_f / days
    average_views
  end

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

  def parse_results(response)
    return unless response
    data = Utils.parse_json(response)
    return data['items'] if data['items']
    # As of October 2017, the data type is https://www.mediawiki.org/wiki/HyperSwitch/errors/not_found
    return no_results if data['type'] =~ %r{errors/not_found}
    raise PageviewApiError, response
  end

  def no_results
    {}
  end

  class PageviewApiError < StandardError; end
end
