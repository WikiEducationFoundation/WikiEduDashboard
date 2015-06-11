json.assignments course.assignments do |assignment|
  json.(assignment, :id, :user_id, :article_id, :article_title, :role)
end