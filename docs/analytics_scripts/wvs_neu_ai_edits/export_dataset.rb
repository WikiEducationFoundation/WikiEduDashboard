#!/usr/bin/env ruby
# frozen_string_literal: true

# Final step of the WVS Northeastern AI-edits dataset pipeline.
#
# Joins leads.csv (written by fetch_leads.rb) with experiment.csv (written
# by import_experiment.rb) on article title, handling the one post-edit
# rename, and writes the final spreadsheet as:
#   - dataset.csv : the final spreadsheet with all columns
#   - dataset.tsv : tab-separated, easier to paste into Google Sheets when
#     leads contain commas
#
# Also prints a sanity-check report to stderr flagging rows with empty
# leads, identical before/after, or missing experiment metadata.
#
# Usage:
#   bundle exec ruby docs/analytics_scripts/wvs_neu_ai_edits/export_dataset.rb

require 'csv'

INPUT = File.expand_path('data/leads.csv', __dir__)
EXPERIMENT = File.expand_path('data/experiment.csv', __dir__)
CSV_OUT = File.expand_path('data/dataset.csv', __dir__)
TSV_OUT = File.expand_path('data/dataset.tsv', __dir__)

COLUMNS = %w[
  title diff_url timestamp revid parentid
  output prompt
  comment lead_before lead_after
].freeze

# When the article was renamed after the experiment, the leads.csv has the
# historic title and experiment.csv has the current title. Map historic ->
# current so the join matches.
TITLE_RENAMES = {
  'Libbie Riley Baer' => 'Libbie C. Riley Baer'
}.freeze

rows = CSV.read(INPUT, headers: true)

metadata = {}
if File.exist?(EXPERIMENT)
  CSV.foreach(EXPERIMENT, headers: true) do |r|
    metadata[r['title']] = { 'output' => r['output'], 'prompt' => r['prompt'] }
  end
else
  warn "#{EXPERIMENT} not found — run import_experiment.rb first. Exporting without output/prompt columns."
end

warnings = Hash.new { |h, k| h[k] = [] }

rows.each do |row|
  lookup_title = TITLE_RENAMES.fetch(row['title'], row['title'])
  meta = metadata[lookup_title] || {}
  row['output'] = meta['output']
  row['prompt'] = meta['prompt']
  warnings[:no_metadata] << row['title'] if metadata.any? && meta.empty?
end

rows.each do |row|
  id = "#{row['title']} (rev #{row['revid']})"
  warnings[:empty_before] << id if row['lead_before'].to_s.strip.empty?
  warnings[:empty_after]  << id if row['lead_after'].to_s.strip.empty?
  warnings[:identical]    << id if row['lead_before'].to_s == row['lead_after'].to_s
  warnings[:tiny_before]  << id if row['lead_before'].to_s.strip.length.between?(1, 30)
end

CSV.open(CSV_OUT, 'w') do |csv|
  csv << COLUMNS
  rows.each { |row| csv << COLUMNS.map { |c| row[c] } }
end

CSV.open(TSV_OUT, 'w', col_sep: "\t", quote_char: "\x00") do |csv|
  csv << COLUMNS
  rows.each do |row|
    csv << COLUMNS.map { |c| row[c].to_s.gsub(/[\t\r\n]+/, ' ') }
  end
end

puts "Wrote #{rows.size} rows to:"
puts "  #{CSV_OUT}"
puts "  #{TSV_OUT}"

warnings.each do |kind, ids|
  next if ids.empty?
  warn ""
  warn "#{kind.to_s.upcase} (#{ids.size}):"
  ids.each { |id| warn "  - #{id}" }
end
