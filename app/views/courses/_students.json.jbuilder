json.students course.courses_users.where(role: 0) do |cu|
  json.(cu, :character_sum_ms, :character_sum_us)
  json.(cu.user, :id, :wiki_id, :trained, :contribution_url)

  json.revisions cu.user.revisions.order(date: :desc).limit(10) do |rev|
    json.(rev, :id, :characters, :views, :date, :url)
    json.article do
      json.title full_title(rev.article)
      json.url article_url(rev.article)
    end
  end
end
