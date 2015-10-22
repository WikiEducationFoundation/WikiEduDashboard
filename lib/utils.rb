#= Utilities
class Utils
  # Take a list of items (ie, course ids) and breaks it into chunks of 50.
  # The Wikipedia liststudents API takes a maximum of 50 course ids per request.
  def self.chunk_requests(items, chunk_size=50)
    blocks = items.each_slice(chunk_size).to_a
    results = []
    blocks.each do |b|
      info = yield b
      results.push(*info)
    end
    results
  end

  def self.parse_json(data)
    begin
      data = JSON.parse data
    rescue JSON::ParserError => e
      Rails.logger.error "Caught #{e}"
    end
    data
  end

  def self.run_on_all(model, method, array)
    array = [array] if array.is_a? model
    model.transaction do
      (array || model.current).each(&method)
    end
  end

  # This method takes user input and tries to convert it into a valid article title
  def self.format_article_title(article_title)
    # Use mb_chars so that we can capitalize unicode letters too.
    article_title[0] = article_title[0].mb_chars.capitalize.to_s
    article_title = article_title.tr(' ', '_')
    article_title
  end
end
