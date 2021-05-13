course = Course.find(18956)

course.revisions.includes(:article).each do |rev|
  next if rev.wiki_id == rev.article.wiki_id
  correct_article = Article.find_by(mw_page_id: rev.mw_page_id, wiki_id: rev.wiki_id)
  if correct_article
    puts "fixing rev: #{rev.id}"
    rev.update(article: correct_article)
  else
    puts "very bad rev: #{rev.id}"
  end
end; nil
