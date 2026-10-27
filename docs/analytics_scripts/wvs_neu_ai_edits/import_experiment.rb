#!/usr/bin/env ruby
# frozen_string_literal: true

# Converts "2025 WVS NEU experiment.xlsx" into a clean experiment.csv with
# only the per-article metadata we care about: title, output (Edited /
# Verbatim / Rejected), and prompt number.
#
# Relies on the `libreoffice` CLI to handle the xlsx -> csv conversion, since
# no XLSX gem is in the project's bundle.
#
# Usage:
#   bundle exec ruby docs/analytics_scripts/wvs_neu_ai_edits/import_experiment.rb

require 'csv'
require 'fileutils'
require 'tmpdir'

XLSX = File.expand_path('data/2025 WVS NEU experiment.xlsx', __dir__)
TMP_DIR = File.join(Dir.tmpdir, 'wvs_neu_xlsx')
OUTPUT = File.expand_path('data/experiment.csv', __dir__)

raise "#{XLSX} not found" unless File.exist?(XLSX)

FileUtils.mkdir_p(TMP_DIR)
system('libreoffice', '--headless', '--convert-to', 'csv',
       '--outdir', TMP_DIR, XLSX, out: File::NULL) ||
  raise('libreoffice conversion failed')

converted = Dir[File.join(TMP_DIR, '*.csv')].first
raise 'no csv produced' unless converted

raw = CSV.read(converted)
# Row 0 is a super-header ("HER NAME", "ORIGINAL", etc.); row 1 is the actual
# column names; data starts at row 2.
data = raw[2..]

experiment_rows = data.select { |r| r[22] && !r[22].to_s.strip.empty? }

CSV.open(OUTPUT, 'w') do |csv|
  csv << %w[title output prompt]
  experiment_rows.each do |r|
    csv << [r[2].to_s.strip, r[22].to_s.strip, r[23].to_s.strip]
  end
end

puts "Wrote #{experiment_rows.size} rows to #{OUTPUT}"

# Flag rows whose Prompt # is unusual (the xlsx has a few decimal values that
# may indicate a typo or a LibreOffice conversion artifact).
anomalies = experiment_rows.reject { |r| r[23].to_s.strip.match?(/\A[1-6]\z/) }
return if anomalies.empty?

warn ''
warn "#{anomalies.size} row(s) with non-integer or out-of-range Prompt #:"
anomalies.each { |r| warn "  - #{r[2]}: prompt=#{r[23].inspect}" }
