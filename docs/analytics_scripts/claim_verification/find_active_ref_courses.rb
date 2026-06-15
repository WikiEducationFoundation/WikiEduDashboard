#!/usr/bin/env ruby
# frozen_string_literal: true

# Lists active courses with recent edits and reference additions — candidates
# for claim-verification diff harvesting (see harvest_reference_diffs.rb).
#
# Hits only public dashboard JSON endpoints; no credentials needed.
#
# Usage:
#   ruby docs/analytics_scripts/claim_verification/find_active_ref_courses.rb
#
# Env:
#   HOST     — dashboard base URL (default https://dashboard.wikiedu.org)
#   CAMPAIGN — campaign slug to scope to (default: all active courses)
#   LIMIT    — max courses to print (default 20)

require 'net/http'
require 'json'
require 'uri'

HOST = ENV.fetch('HOST', 'https://dashboard.wikiedu.org')
CAMPAIGN = ENV.fetch('CAMPAIGN', nil)
LIMIT = ENV.fetch('LIMIT', '20').to_i
USER_AGENT = 'WikiEdu-ClaimVerification-Harvest/1.0 (sage@wikiedu.org)'

def get_json(url)
  uri = URI(url)
  request = Net::HTTP::Get.new(uri)
  request['User-Agent'] = USER_AGENT
  response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
    http.request(request)
  end
  raise "HTTP #{response.code} for #{url}" unless response.code == '200'
  JSON.parse(response.body)
end

path = CAMPAIGN ? "/campaigns/#{CAMPAIGN}/active_courses.json" : '/active_courses.json'
courses = get_json("#{HOST}#{path}")['courses']

# active_courses comes sorted by recent edit volume; surface the ones whose
# students are actually adding references.
with_refs = courses.select { |c| c['references_count'].to_i.positive? }

puts format('%-70s %7s %7s %6s', 'slug', 'recent', 'refs', 'users')
with_refs.first(LIMIT).each do |c|
  puts format('%-70s %7d %7d %6d', c['slug'], c['recent_revision_count'],
              c['references_count'], c['user_count'])
end
puts "\n#{with_refs.size} of #{courses.size} active courses have reference additions."
puts "Next: COURSE='<slug>' ruby docs/analytics_scripts/claim_verification/harvest_reference_diffs.rb"
