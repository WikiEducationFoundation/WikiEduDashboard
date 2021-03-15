# Use this to find article titles that won't work correctly as Wikipedia titles
# Destroy the ones that don't have any assignments associated with them
# Fix or remove the assignments manually, then run this again until you've fixed
# them all.
bad_titles = Article.where(mw_page_id: 0).pluck(:title)

Article.where(mw_page_id: 0).each do |a|
  t = a.title
  assignment = Assignment.find_by(article_title: t)
  puts t
  puts 'NONE' unless assignment
  unless assignment
    a.destroy
    next
  end
  puts assignment.article_id
  puts assignment.course.slug
end

Article.where(mw_page_id: 0).each { |a| a.assignments.each { |ass| ass.update(article_id: nil ) }; a.destroy }
