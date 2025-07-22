load "#{Rails.root}/lib/wikidata_summary_parser.rb"

campaign = Campaign.find_by_slug 'wikidata_stats'

i = 0

campaign.courses.each do |course|
  course.revisions.each do |rev|
    i += 1
    puts i
    next if rev.summary
    rev.update(summary: WikidataSummaryParser.fetch_summary(rev))
  end
end


campaign.courses.each { |c| puts c.slug; WikidataSummaryParser.analyze_revisions(c.revisions.where(wiki: c.home_wiki)) }
