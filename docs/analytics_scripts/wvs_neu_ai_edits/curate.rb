#!/usr/bin/env ruby
# frozen_string_literal: true

# Step 1.5 of the WVS Northeastern AI-edits dataset pipeline.
#
# Filters contributions.csv down to only the articles on the expected list
# (expected_titles.txt), with one rename accommodation: "Libbie Riley Baer"
# (title at time of edit) is kept because the article has since been renamed
# to "Libbie C. Riley Baer", which is how it appears on the expected list.
#
# Also consolidates multi-edit articles: when the same article has more than
# one kept edit (e.g. a follow-up refinement minutes later), they are merged
# into a single row whose span covers them all — parent of the earliest edit
# through revid of the latest.
#
# Writes contributions.curated.csv.
#
# Usage:
#   bundle exec ruby docs/analytics_scripts/wvs_neu_ai_edits/curate.rb

require 'csv'
require 'set'
require 'uri'

INPUT = File.expand_path('data/contributions.csv', __dir__)
EXPECTED = File.expand_path('data/expected_titles.txt', __dir__)
OUTPUT = File.expand_path('data/contributions.curated.csv', __dir__)

# Articles whose title at edit-time differs from the title on the expected list
# because the article was renamed after the edit. Key: historic title in the
# contributions feed; value: current title as it appears on the expected list.
RENAMES = {
  'Libbie Riley Baer' => 'Libbie C. Riley Baer'
}.freeze

expected = File.readlines(EXPECTED).map(&:strip).reject(&:empty?).to_set
rows = CSV.read(INPUT, headers: true)

kept = []
dropped = []
rows.each do |r|
  if expected.include?(r['title']) || RENAMES.key?(r['title'])
    kept << r
  else
    dropped << r
  end
end

# When the same article has multiple kept edits (e.g. a student making a
# follow-up refinement minutes later), consolidate into a single row whose
# span covers them all: parent of the earliest edit -> revid of the latest.
consolidated = []
merges = []
kept.group_by { |r| r['title'] }.each do |title, group|
  if group.size == 1
    consolidated << group.first
    next
  end
  ordered = group.sort_by { |r| r['timestamp'] }
  first = ordered.first
  last = ordered.last
  merged = last.dup
  merged['parentid'] = first['parentid']
  merged['diff_url'] = "https://en.wikipedia.org/w/index.php?" \
    "title=#{URI.encode_www_form_component(last['title'])}" \
    "&diff=#{last['revid']}&oldid=#{first['parentid']}"
  consolidated << merged
  merges << [title, ordered.map { |r| r['revid'] }]
end

CSV.open(OUTPUT, 'w') do |csv|
  csv << rows.headers
  consolidated.each { |r| csv << r.fields }
end

puts "Kept #{consolidated.size} rows covering #{consolidated.map { |r| r['title'] }.uniq.size} articles."
puts "Dropped #{dropped.size} rows:"
dropped.each { |r| puts "  - #{r['title']}  (rev #{r['revid']}, #{r['timestamp'][0, 10]})" }
unless merges.empty?
  puts "Consolidated #{merges.size} multi-edit article#{'s' if merges.size != 1}:"
  merges.each { |title, revids| puts "  - #{title}: revs #{revids.join(' + ')} -> single spanning row" }
end
puts "Wrote #{OUTPUT}"

missing_from_actual = expected - rows.map { |r| r['title'] }.to_set - RENAMES.values.to_set
unless missing_from_actual.empty?
  puts
  puts "Expected titles with no auto-detected AI-tagged edit (#{missing_from_actual.size}):"
  missing_from_actual.each { |t| puts "  - #{t}" }
end
