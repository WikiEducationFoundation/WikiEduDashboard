# frozen_string_literal: true

# Sends every row of a JSONL input file (each row has an `id` and a `text`) to
# Pangram 4 (the `pangram-4` model; the response's `version` says which release
# answered) and saves each response to data/results/<id>.json. Resumable: rows
# with a saved result are skipped. Run with
#   INPUT=data/study1_inputs.jsonl THREADS=4 \
#     bin/rails runner docs/analytics_scripts/pangram_window_splitting/score_inputs.rb
# INPUT is relative to this directory.

require 'json'
require_dependency "#{Rails.root}/lib/pangram_api"

base = File.join(Rails.root, 'docs/analytics_scripts/pangram_window_splitting')
results = File.join(base, 'data/results')
FileUtils.mkdir_p(results)

rows = File.readlines(File.join(base, ENV.fetch('INPUT'))).map { |line| JSON.parse(line) }
pending = rows.reject { |row| File.exist?(File.join(results, "#{row['id']}.json")) }
puts "#{rows.size} rows, #{pending.size} pending"

queue = Queue.new
pending.each { |row| queue << row }
done = Concurrent::AtomicFixnum.new(0)
mutex = Mutex.new

workers = Array.new(ENV.fetch('THREADS', '4').to_i) do
  Thread.new do
    api = PangramApi.v4
    while (row = (queue.pop(true) rescue nil)) # rubocop:disable Style/RescueModifier
      attempts = 0
      begin
        response = api.inference(row['text'])
        File.write(File.join(results, "#{row['id']}.json"),
                   JSON.pretty_generate('id' => row['id'], 'scored_at' => Time.now.utc.iso8601,
                                        'response' => response))
        count = done.increment
        mutex.synchronize { puts "#{count}/#{pending.size} #{row['id']}" } if (count % 10).zero?
      rescue PangramApi::Error, Faraday::Error => e
        attempts += 1
        sleep 5 * attempts
        retry if attempts < 3
        mutex.synchronize { puts "FAILED #{row['id']}: #{e.class} #{e.message[0, 200]}" }
      end
    end
  end
end
workers.each(&:join)
puts "done: #{done.value} scored"
