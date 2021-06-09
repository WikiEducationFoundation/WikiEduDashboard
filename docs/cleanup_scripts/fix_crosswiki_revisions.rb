
def fix_revisions(course)
  puts course.slug
  course.all_revisions.includes(:article).each do |rev|
    next if rev.wiki_id == rev.article.wiki_id
    correct_article = Article.find_by(mw_page_id: rev.mw_page_id, wiki_id: rev.wiki_id)
    if correct_article
      puts "fixing rev: #{rev.id}"
      rev.update(article: correct_article)
    else
      puts "very bad rev: #{rev.id}"
    end
  end
  return nil
end

Course.where("revision_count < 5000").last(600).each { |course| fix_revisions(course) }


i = 0
Revision.where(id: 702925015..972925015).includes(:article).in_batches do |batch|
  i += 1
  puts "batch #{i}"
  batch.each do |rev|
    next if rev.wiki_id == rev.article&.wiki_id
    correct_article = Article.find_by(mw_page_id: rev.mw_page_id, wiki_id: rev.wiki_id)
    if correct_article
      puts "fixing rev: #{rev.id}"
      rev.update(article: correct_article)
    else
      puts "very bad rev: #{rev.id}"
    end
  end
  nil
end; nil
