# frozen_string_literal: true

# Builds the study 3 inputs (see README.md): pre-ChatGPT student peer reviews,
# taken from the "User:Owner/Article/Reviewer Peer Review" subpages the Wiki Ed
# peer review exercise created. For each page, the reviewer's last revision before
# CUTOFF is extracted with GetRevisionPlaintext, as production would extract it.
# Run with
#   bin/rails runner docs/analytics_scripts/pangram_window_splitting/collect_peer_reviews.rb
# Writes data/study3_inputs.jsonl and data/study3_candidates.json (the search results).

require 'json'

TARGET = 50
CUTOFF = '2022-06-30T00:00:00Z'
WORDS = (200..1000)
API = 'https://en.wikipedia.org/w/api.php'
UA = 'https://github.com/WikiEducationFoundation/WikiEduDashboard'

dir = File.join(Rails.root, 'docs/analytics_scripts/pangram_window_splitting/data')
FileUtils.mkdir_p(dir)
http = Faraday.new(url: API, headers: { 'User-Agent' => UA })
# Wikimedia refuses bursts of requests, so pause between calls and back off once if refused.
get = lambda do |params|
  sleep 1
  response = http.get('', params.merge(format: 'json', formatversion: 2))
  return JSON.parse(response.body) if response.success?

  sleep 60
  JSON.parse(http.get('', params.merge(format: 'json', formatversion: 2)).body)
end
# Page ids below this were created before mid-2022, so their reviews can predate CUTOFF.
MAX_PAGE_ID = 70_500_000

candidates_path = File.join(dir, 'study3_candidates.json')
titles = if File.exist?(candidates_path)
           JSON.parse(File.read(candidates_path))
         else
           (0...8000).step(500).flat_map do |offset|
             get.(action: 'query', list: 'search', srnamespace: 2, srlimit: 500, sroffset: offset,
                  srsearch: 'intitle:"Peer Review" insource:"Dashboard.wikiedu.org peer review"',
                  srprop: '')['query']['search'].map { |hit| [hit['title'], hit['pageid']] }
           end.tap { |found| File.write(candidates_path, JSON.pretty_generate(found)) }
         end

wiki = Wiki.get_or_create(language: 'en', project: 'wikipedia')
# Short lines that are headings, labels or links rather than prose.
prose_only = lambda do |text|
  text.lines.map(&:strip).select { |line| line.split.size >= 8 || line.match?(/[.!?)]\z/) }
      .join("\n\n")
end

rows = []
titles = titles.select { |_title, page_id| page_id < MAX_PAGE_ID }.map(&:first)
titles.shuffle(random: Random.new(20261116)).each do |title|
  break if rows.size >= TARGET
  reviewer = title[%r{/([^/]+) Peer Review\z}, 1]
  next unless reviewer

  page = get.(action: 'query', prop: 'revisions', titles: title, rvprop: 'ids|timestamp|user',
              rvstart: CUTOFF, rvdir: 'older', rvlimit: 1)['query']['pages'].first
  rev = page['revisions']&.first
  next unless rev && rev['user'].tr('_', ' ') == reviewer.tr('_', ' ')

  text = GetRevisionPlaintext.new(rev['revid'], wiki, diff_mode: false).plain_text
  next unless text && WORDS.cover?(text.split.size)

  meta = { title:, rev_id: rev['revid'], timestamp: rev['timestamp'], group: 'peer_review',
           words: text.split.size }
  rows << meta.merge(id: "s3-#{rev['revid']}-original", variant: 'original', text:)
  rows << meta.merge(id: "s3-#{rev['revid']}-prose_only", variant: 'prose_only',
                     text: prose_only.(text))
  unescaped = CGI.unescapeHTML(text)
  if unescaped != text
    rows << meta.merge(id: "s3-#{rev['revid']}-entities_fixed", variant: 'entities_fixed',
                       text: unescaped)
  end
  puts "#{rows.count { |r| r[:variant] == 'original' }}: #{title} (#{rev['timestamp']})"
end

File.write(File.join(dir, 'study3_inputs.jsonl'), rows.map(&:to_json).join("\n") + "\n")
puts "study 3: #{rows.size} rows, #{rows.sum { |r| r[:text].split.size }} words"
