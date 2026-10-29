#!/usr/bin/env ruby
# frozen_string_literal: true

# Step 2 of the WVS Northeastern AI-edits dataset pipeline.
#
# Reads contributions.curated.csv (written by curate.rb) and, for each edit,
# fetches the plaintext of the lead section (section=0) of both the parent
# and new revision via the MediaWiki parse API. Writes leads.csv with two
# new columns: lead_before, lead_after.
#
# Usage:
#   bundle exec ruby docs/analytics_scripts/wvs_neu_ai_edits/fetch_leads.rb

require 'net/http'
require 'json'
require 'csv'
require 'uri'
require 'nokogiri'

API_URL = URI('https://en.wikipedia.org/w/api.php')
USER_AGENT = 'WikiEduDashboard AI-edits dataset builder (https://github.com/WikiEducationFoundation/WikiEduDashboard)'
INPUT = File.expand_path('data/contributions.curated.csv', __dir__)
OUTPUT = File.expand_path('data/leads.csv', __dir__)

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

# Fetches just the lead section (section=0) HTML for a given revision id.
# Returns nil if the revision is deleted/missing or has no section 0.
def fetch_lead_html(revid)
  return nil if revid.to_i.zero?
  data = get(
    action: 'parse',
    oldid: revid,
    prop: 'text',
    section: 0,
    format: 'json',
    formatversion: 2,
    disableeditsection: 1,
    disabletoc: 1
  )
  data.dig('parse', 'text')
rescue RuntimeError => e
  warn "  ! rev #{revid}: #{e.message}"
  nil
end

# HTML -> plaintext, mirroring GetRevisionPlaintext's cleanup:
# strips infoboxes, figures, images, citation markers, and edit-button leftovers.
def html_to_plaintext(html)
  return '' if html.nil? || html.empty?
  doc = Nokogiri::HTML.fragment(html)
  doc.xpath('.//style').each(&:remove)
  doc.xpath('.//script').each(&:remove)
  doc.xpath('.//table').each(&:remove)
  doc.xpath('.//figure').each(&:remove)
  doc.xpath('.//img').each(&:remove)
  doc.xpath('.//cite').each(&:remove)
  doc.css('.mw-cite-backlink').each(&:remove)
  doc.css('.reference').each(&:remove)
  doc.css('sup.reference').each(&:remove)
  # Strip the {{Short description}} render — it's a hidden one-liner above
  # the lead (e.g. "American journalist, poet") that would prepend itself to
  # the extracted plaintext otherwise.
  doc.css('.shortdescription').each(&:remove)
  # The MediaWiki parser emits "Cite error: The named reference X was
  # invoked but never defined" when rendering section=0 in isolation,
  # because the <references/> list lives outside the lead section.
  doc.css('.mw-ext-cite-error, .cite-error, .error').each(&:remove)
  text = doc.text
  text = text.gsub('[edit]', '')
  text = text.gsub(/\[\d+\]/, '')
  text = text.gsub(/^.*Cite error:.*$/, '')
  text = text.gsub(/\r\n?/, "\n")
  text = text.gsub(/\n{3,}/, "\n\n")
  text.strip
end

rows = CSV.read(INPUT, headers: true)
total = rows.size
puts "Processing #{total} edits..."

CSV.open(OUTPUT, 'w') do |csv|
  csv << (rows.headers + %w[lead_before lead_after])
  rows.each_with_index do |row, i|
    warn "[#{i + 1}/#{total}] #{row['title']} (rev #{row['revid']})"

    before_html = fetch_lead_html(row['parentid'])
    after_html  = fetch_lead_html(row['revid'])

    csv << (row.fields + [
      html_to_plaintext(before_html),
      html_to_plaintext(after_html)
    ])
  end
end

puts "Wrote #{OUTPUT}"
