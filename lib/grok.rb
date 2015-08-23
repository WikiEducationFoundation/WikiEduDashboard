#= Fetches pageview data by sending GET requests to stats.grok.se
class Grok
  ################
  # Entry points #
  ################
  # Given an article title and a date, return the number of page views for every
  # day from that date until today.
  #
  # [title]  title of a Wikipedia page (including namespace, if applicable)
  # [date]   a specific date
  def self.views_for_article(title, date, language=nil)
    language = Figaro.env.wiki_language if language.nil?
    i_date = date
    views = {}
    while Date.today >= i_date
      data = monthly_views(title, i_date.strftime('%Y%m'), language)
      return views unless data
      data = Utils.parse_json(data)
      if data.include?('daily_views')
        data['daily_views'].each do |day, view_count|
          views[day] = view_count if view_count > 0 && day.to_date >= date
        end
      end
      i_date += 1.month
    end
    views
  end

  def self.average_views_for_article(title, language=nil)
    language = Figaro.env.wiki_language if language.nil?
    data = sixty_day_views(title, language)
    return unless data
    data = Utils.parse_json(data)
    return unless data.include?('daily_views')
    views_per_day = data['daily_views'].values
    days = views_per_day.count
    total_views = views_per_day.inject(:+) # sum of the array
    average_views = total_views.to_f / days
    average_views
  end

  ##################
  # Helper methods #
  ##################
  def self.monthly_views(title, month, language)
    title = URI.escape(title)
    url = "http://stats.grok.se/json/#{language}/#{month}/#{title}"
    api_get url
  end

  def self.sixty_day_views(title, language)
    title = URI.escape(title)
    url = "http://stats.grok.se/json/#{language}/latest60/#{title}"
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
      Rails.logger.error I18n.t('timeout', api: 'grok.se', tries: (tries -= 1))
      retry unless tries.zero?
    rescue StandardError => e
      Rails.logger.error "Grok.se socket error: #{e}"
      Raven.capture_exception e
    end
  end
end
