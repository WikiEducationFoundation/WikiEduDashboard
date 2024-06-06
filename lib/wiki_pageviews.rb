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
    calculate_average_views(daily_view_data)
  end

  ##################
  # Helper methods #
  ##################
  private

  def recent_views
    start_date = 50.days.ago
    end_date = 1.day.ago
    url = query_url(start_date:, end_date:)
    parse_results(api_get(url))
  end

  def query_url(start_date:, end_date:)
    title = CGI.escape(@title)
    base_url = 'https://wikimedia.org/api/rest_v1/metrics/pageviews/'
    configuration_params = "per-article/#{wiki_url_param}/all-access/user/"
    start_param = start_date.strftime('%Y%m%d')
    end_param = end_date.strftime('%Y%m%d')
    title_and_date_params = "#{title}/daily/#{start_param}00/#{end_param}00"
    base_url + configuration_params + title_and_date_params
  end

  def fetch_view_data(start_date, end_date)
    url = query_url(start_date:, end_date:)
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
    total_views.to_f / days
  end

  def api_get(url)
    tries ||= 3
    Net::HTTP::get(URI.parse(url))
  rescue EOFError, Errno::ETIMEDOUT, Errno::ENETUNREACH, SocketError
    Rails.logger.info I18n.t('timeout', api: 'wikimedia.org/api/rest_v1', tries: (tries -= 1))
    retry unless tries.zero?
  end

  def parse_results(response)
    return unless response
    data = Utils.parse_json(response)
    return data['items'] if data['items']

    # Since the API experienced some changes in the response when handling requests for which no
    # data is available, we decided to rely only on the data status being 404 to return no results
    return no_results if data['status'] == 404
    raise PageviewApiError, response
  end

  def no_results
    {}
  end

  def wiki_url_param
    # Wikidata works with either "www.wikidata" or just "wikidata", but not ".wikidata"
    @wiki.language ? "#{@wiki.language}.#{@wiki.project}" : @wiki.project
  end

  class PageviewApiError < StandardError; end
end
