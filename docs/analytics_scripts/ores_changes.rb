# frozen_string_literal: true

term = Campaign.find_by(slug: 'spring_2017')

first_revs = []
term.courses.each do |course|
  course.articles_courses.each do |ac|
    first_revs << ac.all_revisions.order('date ASC').first
  end
end

importer = RevisionScoreImporter.new

first_revs.each do |rev|
  next if rev.nil?
  next if rev.wp10_previous
  next if rev.wiki_id != 1
  puts rev.id
  importer.send(:update_wp10_previous, rev)
end; first_revs.count
