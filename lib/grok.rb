# This class fetches pageview data by sending GET requests to stats.grok.se

class Grok

  # Given an article title and a date, return the number of page views for every
  # day from that date until today.
  #
  # [title]  title of a Wikipedia page (including namespace, if applicable)
  # [date]   a specific date
  # [language] the language version of Wikipedia
  def self.get_views_since_date_for_article(title, date, language = Figaro.env.wiki_language)
    iDate = date
    views = Hash.new
    while Date.today >= iDate do
      data = Grok.api_get(title, iDate.strftime("%Y%m"), language)
      begin
        data = JSON.parse data
      rescue JSON::ParserError => e
        puts "Caught #{e}"
      end
      if data.include?("daily_views")
        data["daily_views"].each do |day, view_count|
          if(view_count > 0 && day.to_date >= date)
            views[day] = view_count
          end
        end
      end
      iDate += 1.month
    end
    return views
  end



  ###################
  # Private methods #
  ###################
  private
  def self.api_get(title, month, language)
    title = URI.escape(title)
    url = "http://stats.grok.se/json/#{language}/#{month}/#{title}"
    Net::HTTP::get(URI.parse(url))
  end

end
