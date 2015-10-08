json.assignments course.assignments do |assignment|
  json.(assignment, :id, :user_id, :article_id, :article_title, :role)
  json.article_title assignment.article_title.tr('_', ' ')

  wiki_lang = ENV['wiki_language']
  if assignment.article.try(:language).present? && assignment.article.language != wiki_lang
    json.language assignment.article.language
  end

  json.article_url assignment.page_url
  json.user_wiki_id assignment.user.wiki_id
end
