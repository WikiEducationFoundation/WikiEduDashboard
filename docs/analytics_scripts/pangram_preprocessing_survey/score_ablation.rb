# Scores ablation inputs with Pangram 4 and saves each raw response.
#   bin/rails runner score_ablation.rb ~/pangram_preprocessing_survey
# Reads ablation_inputs.json (from build_ablation.py); writes ablation_results/<id>.json.
# Resumable: existing results are skipped. Needs a checkout with pangram_api_key set.
require 'json'
require_dependency "#{Rails.root}/lib/pangram_api"

dir = File.expand_path(ARGV[0])
out = File.join(dir, 'ablation_results')
FileUtils.mkdir_p(out)
api = PangramApi.v4
inputs = JSON.parse(File.read(File.join(dir, 'ablation_inputs.json')))
inputs.each_with_index do |input, i|
  path = File.join(out, "#{input['id']}.json")
  next if File.exist?(path)

  begin
    File.write(path, JSON.generate({ 'input' => input, 'response' => api.inference(input['text']) }))
  rescue StandardError => e
    puts "#{input['id']}: #{e.class}: #{e.message[0, 200]}"
  end
  puts "#{i + 1}/#{inputs.size}" if ((i + 1) % 10).zero?
end
puts "#{Dir[File.join(out, '*.json')].size} results in #{out}"
