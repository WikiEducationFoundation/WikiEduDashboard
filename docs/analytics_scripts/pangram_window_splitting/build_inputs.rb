# frozen_string_literal: true

# Builds the inputs for studies 1 and 2 (see README.md) from detector comparison
# units that Pangram 4.0 already scored. Run in a Rails console or with
#   bin/rails runner docs/analytics_scripts/pangram_window_splitting/build_inputs.rb
# Writes data/study1_inputs.jsonl and data/study2_inputs.jsonl. Seeded, so a re-run
# picks the same units.

require 'json'

dir = File.join(Rails.root, 'docs/analytics_scripts/pangram_window_splitting/data')
FileUtils.mkdir_p(dir)
rng = Random.new(20261116)

scores = RevisionAiScore.where(check_type: RevisionAiScore::PANGRAM_V4_KEY)
                        .where.not(sample_id: nil, avg_ai_likelihood: nil)
                        .includes(:sample)
                        .select { |s| s.details['version'] == '4.0' && s.sample }
scores = scores.select { |s| s.sample.word_count.between?(300, 1500) }
                .uniq { |s| s.sample.text_sha256 }

multi = ->(s) { (s.details['windows'] || []).size > 1 }
groups = {
  'human' => scores.select { |s| s.sample.ground_truth == 'human' },
  'ai_one_window' => scores.select { |s| s.sample.ground_truth == 'ai' && !multi.(s) },
  'ai_split' => scores.select { |s| s.sample.ground_truth == 'ai' && multi.(s) }
}

study1 = groups.flat_map do |group, members|
  members.sample(50, random: rng).map do |s|
    unit = s.sample
    { id: "s1-#{unit.id}", unit_id: unit.id, group:, variant: 'original',
      sample_name: unit.sample_name, words: unit.word_count, origin: unit.factors&.dig('origin'),
      text: unit.plain_text, v40: s.details }
  end
end
File.write(File.join(dir, 'study1_inputs.jsonl'), study1.map(&:to_json).join("\n") + "\n")

# Study 2: trivial edits to a subset of study 1. Each variant changes one thing.
HEADER = "Notes on this draft\nStudentEditor\n\n"
SIGNATURE = "\n\nStudentEditor (talk) 16:15, 15 November 2026 (UTC)"
# Swap the " and " nearest the middle of the text, so the edit falls inside a window.
middle_and = lambda do |text, replacement|
  spots = text.enum_for(:scan, / and /).map { Regexp.last_match.begin(0) }
  return nil if spots.empty?
  spot = spots.min_by { |i| (i - text.length / 2).abs }
  text[0...spot] + replacement + text[(spot + 5)..]
end
VARIANTS = {
  'header' => ->(t) { HEADER + t },
  'signature' => ->(t) { t + SIGNATURE },
  'amp_entity' => ->(t) { middle_and.(t, ' &amp; ') },
  'amp_plain' => ->(t) { middle_and.(t, ' & ') },
  'single_newlines' => ->(t) { t.gsub(/\n{2,}/, "\n") },
  'no_newlines' => ->(t) { t.gsub(/\s*\n\s*/, ' ') }
}.freeze

picks = { 'human' => 15, 'ai_one_window' => 15, 'ai_split' => 10 }
study2 = picks.flat_map do |group, n|
  study1.select { |row| row[:group] == group && row[:text].include?(' and ') }
        .sample(n, random: rng)
        .flat_map do |row|
          VARIANTS.filter_map do |variant, edit|
            text = edit.(row[:text])
            next if text.nil? || text == row[:text]
            row.except(:v40).merge(id: "s2-#{row[:unit_id]}-#{variant}", variant:, text:)
          end
        end
end
File.write(File.join(dir, 'study2_inputs.jsonl'), study2.map(&:to_json).join("\n") + "\n")

puts "study 1: #{study1.size} texts, #{study1.sum { |r| r[:words] }} words"
puts "study 2: #{study2.size} variants, #{study2.sum { |r| r[:words] }} words"
