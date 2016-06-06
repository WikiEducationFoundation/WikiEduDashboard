json.assignments course.assignments do |assignment|
  json.call(assignment, :id, :user_id, :article_id, :article_title, :role)
  json.assignment_id assignment.id
  json.article_title assignment.article_title.tr('_', ' ')

  if assignment.article
    json.article_rating assignment.article.rating
    json.article_rating_num rating_priority(assignment.article.rating) 
    json.article_pretty_rating rating_display(assignment.article.rating)
  end

  unless assignment.wiki_id == course.home_wiki.id
    json.language assignment.wiki.language
    json.project assignment.wiki.project
  end

  json.article_url assignment.page_url

  if assignment.user
    json.username assignment.user.username
  end
end
