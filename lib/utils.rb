# frozen_string_literal: true

#= Utilities
class Utils
  # Take a list of items (ie, course ids) and breaks it into chunks of 50.
  def self.chunk_requests(items, chunk_size=50)
    blocks = items.each_slice(chunk_size).to_a
    results = []
    blocks.each do |b|
      info = yield b
      results.concat Array(info)
    end
    results
  end

  def self.parse_json(data)
    begin
      data = Oj.load(data)
    rescue Oj::ParseError => e
      Rails.logger.info "Caught #{e}"
    end
    data
  end
end
