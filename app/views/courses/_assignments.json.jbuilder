json.assignments course.assignments do |assignment|
  json.call(assignment, :user_id, :article_id, :article_title, :role)
  json.assignment_id assignment.id
  json.article_title assignment.article_title.tr('_', ' ')

  unless assignment.wiki_id == course.home_wiki.id
    json.language assignment.wiki.language
    json.project assignment.wiki.project
  end

  json.article_url assignment.page_url
  json.username assignment.user.username
end
