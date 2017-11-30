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
      data = JSON.parse data
    rescue JSON::ParserError => e
      Rails.logger.error "Caught #{e}"
    end
    data
  end

  def self.run_on_all(model, method, array)
    array = [array] if array.is_a? model
    (array&.in_groups_of(200, false) ||
      model.ready_for_update.find_in_batches(batch_size: 200)
    ).each do |group|
      model.transaction { group.each(&method) }
    end
  end
end
