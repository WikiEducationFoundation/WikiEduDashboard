# This find records that violate the constraint of only one non-deleted article mw_page_id per wiki.
# It deletes the ones that don't have any other records associated with them.
# The remaining duplicates will need to be investigated further.
duplicate_counts = Article.where(deleted: false).group(:mw_page_id, :wiki_id).having('count(*) > 1').count
# duplicate_counts keys are like [mw_page_id, wiki_id]

duplicate_counts.keys.each do |key|
  mw_page_id = key[0]
  wiki_id = key[1]
  articles = Article.where(mw_page_id: mw_page_id, wiki_id: wiki_id, deleted: false)
  articles.each do |art|
    puts art.id
    puts art.title
    next if art.assignments.any?
    next if art.revisions.any?
    next if art.articles_courses.any?
    puts 'No records!'
    art.destroy
  end
end
