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
end

scores = []
term.courses.each do |course|
  course.articles_courses.each do |ac|
    ordered_revisions = ac.all_revisions.order('date ASC')
    first_revision = ordered_revisions.first
    last_revision = ordered_revisions.last
    scores << [first_revision&.wp10_previous || 0.0, last_revision&.wp10 || 0.0]
  end
end

CSV.open("/home/sage/#{term.slug}_ores_diff.csv", 'wb') { |csv| scores.each { |s| csv << s } }
