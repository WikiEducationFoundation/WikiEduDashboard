json.students course.courses_users.where(role: 0) do |cu|
  json.(cu, :character_sum_ms, :character_sum_us)
  json.(cu.user, :id, :wiki_id, :trained, :contribution_url)

  if cu.assignments.assigned.blank?
    json.assignment_title 'zzzz'
  else
    json.assignment_title cu.assignments.assigned.order(created_at: :desc).first.article_title
  end

  if cu.assignments.reviewing.blank?
    json.reviewing_title 'zzzz'
  else
    json.reviewing_title cu.assignments.reviewing.order(created_at: :desc).first.article_title
  end

  json.revisions cu.user.revisions.order(date: :desc).limit(10) do |rev|
    json.(rev, :id, :characters, :views, :date, :url)
    json.article do
      json.title full_title(rev.article)
      json.url article_url(rev.article)
    end
  end
end
