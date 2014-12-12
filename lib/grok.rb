class Grok

  def self.get_page_view_data_for_article(title, month=nil)    
    if month.nil?
      month = Date.today.strftime("%Y%m")
    end
    Grok.api_get(title, month)
  end

  def self.get_month_views_for_article(title, month)
    data = Grok.get_page_view_data_for_article(title, month)
    data = JSON.parse data
    total = 0
    data["daily_views"].each do |day, views|
      total += views
    end
    total
  end

  def self.get_day_views_for_article(title, date)
    data = Grok.get_page_view_data_for_article(title, date.strftime("%Y%m"))
    data = JSON.parse data
    data["daily_views"][date.strftime("%Y-%m-%d")]
  end


  private

  def self.api_get(title, month)
    title = URI.escape(title)
    url = "http://stats.grok.se/json/en/#{month}/#{title}"
    Net::HTTP::get(URI.parse(url))
  end

end