#= Fetches pageview data by sending GET requests to stats.grok.se
class Grok
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
      data = api_get(title, i_date.strftime('%Y%m'), language)
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

  ###################
  # Private methods #
  ###################
  class << self
    private

    def api_get(title, month, language)
      tries ||= 3
      title = URI.escape(title)
      url = "http://stats.grok.se/json/#{language}/#{month}/#{title}"
      Net::HTTP::get(URI.parse(url))
    rescue Errno::ETIMEDOUT
      Rails.logger.error I18n.t('timeout', api: 'grok.se', tries: (tries -= 1))
      retry unless tries.zero?
    end
  end
end
