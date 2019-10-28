# Find out how many students are making edits to the pages that have preloaded templates:
# the sandbox URLs for assigned articles, peer review links for classmates' articles, and the Evaluate_an_Article assignment

sandbox_assignment_edits = 0
peer_review_edits = 0
evaluate_edits = 0

i = 1

Campaign.find_by_slug('fall_2019').students.each do |student|
  puts i
  article_ids = student.revisions.pluck(:article_id)
  titles_edited = Article.where(id: article_ids).pluck(:title)
  evaluate_edits += 1 if titles_edited.any? { |title| title.match? /Evaluate_an_Article/ }
  sandboxes = student.assignments.pluck(:sandbox_url).map { |url| url.gsub('https://en.wikipedia.org/wiki/User:', '') }
  sandbox_assignment_edits += 1 if sandboxes.any? { |url| titles_edited.include? url }
  peer_review_edits +=1 if titles_edited.any? { |title| title.match? /_Peer_Review/ }
  i += 1
end

puts "sandbox drafts edited: #{sandbox_assignment_edits}"
puts "peer review pages edited: #{peer_review_edits}"
puts "article evaluation edits: #{evaluate_edits}"
