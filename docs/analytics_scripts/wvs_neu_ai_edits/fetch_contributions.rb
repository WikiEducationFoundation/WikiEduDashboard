#!/usr/bin/env ruby
# frozen_string_literal: true

# Step 1 of the WVS Northeastern AI-edits dataset pipeline.
#
# Queries User:Rosiestep's contribution history on en.wikipedia and writes
# every edit whose summary matches the AI-assisted pattern documented at
# https://en.wikipedia.org/wiki/User:Rosiestep/WVS_Northeastern_University/Research
# to data/contributions.csv.
#
# Usage:
#   bundle exec ruby docs/analytics_scripts/wvs_neu_ai_edits/fetch_contributions.rb

require 'net/http'
require 'json'
require 'csv'
require 'fileutils'
require 'uri'

USERNAME = 'Rosiestep'
API_URL = URI('https://en.wikipedia.org/w/api.php')
USER_AGENT = 'WikiEduDashboard AI-edits dataset builder (https://github.com/WikiEducationFoundation/WikiEduDashboard)'
AI_SUMMARY_RE = /assisted by generative AI/i
OUTPUT = File.expand_path('data/contributions.csv', __dir__)

def get(params)
  uri = API_URL.dup
  uri.query = URI.encode_www_form(params)
  req = Net::HTTP::Get.new(uri)
  req['User-Agent'] = USER_AGENT
  Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
    res = http.request(req)
    raise "HTTP #{res.code}: #{res.body[0, 200]}" unless res.is_a?(Net::HTTPSuccess)
    JSON.parse(res.body)
  end
end

def diff_url(title, revid, parentid)
  "https://en.wikipedia.org/w/index.php?title=#{URI.encode_www_form_component(title)}" \
    "&diff=#{revid}&oldid=#{parentid}"
end

matches = []
uccontinue = nil
pages = 0

loop do
  params = {
    action: 'query',
    list: 'usercontribs',
    ucuser: USERNAME,
    uclimit: 500,
    ucprop: 'ids|title|timestamp|comment|flags',
    format: 'json',
    formatversion: 2
  }
  params[:uccontinue] = uccontinue if uccontinue

  data = get(params)
  batch = data.dig('query', 'usercontribs') || []
  pages += 1

  batch.each do |c|
    next unless AI_SUMMARY_RE.match?(c['comment'].to_s)
    matches << c
  end

  warn "page #{pages}: #{batch.size} contribs scanned, #{matches.size} matches so far"
  uccontinue = data.dig('continue', 'uccontinue')
  break unless uccontinue
end

FileUtils.mkdir_p(File.dirname(OUTPUT))
CSV.open(OUTPUT, 'w') do |csv|
  csv << %w[revid parentid title timestamp comment diff_url]
  matches.each do |c|
    csv << [
      c['revid'],
      c['parentid'],
      c['title'],
      c['timestamp'],
      c['comment'],
      diff_url(c['title'], c['revid'], c['parentid'])
    ]
  end
end

puts "Wrote #{matches.size} matching edits to #{OUTPUT}"
