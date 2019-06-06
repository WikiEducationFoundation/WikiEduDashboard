# frozen_string_literal: true

term = Campaign.find_by(slug: 'spring_2017')

all_revs = []
term.courses.each do |course|
  course.articles_courses.each do |ac|
    all_revs << ac.all_revisions
  end
end

importer = RevisionScoreImporter.new

all_revs.each do |rev|
  next if rev.nil?
  next if rev.wp10_previous
  next if rev.wiki_id != 1
  puts rev.id
  importer.send(:update_wp10_previous, rev)
end; all_revs.count
