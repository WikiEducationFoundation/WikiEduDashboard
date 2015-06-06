json.courses_users course.courses_users do |cu|
  json.(cu, :character_sum_ms, :character_sum_us, :role)
  json.user do
    json.(cu.user, :id, :wiki_id, :trained, :contribution_url)
    json.assignments cu.user.assignments do |ass|
      json.(ass, :id, :article_title)
      json.article_url article_url(ass.article)
    end
    json.revisions cu.user.revisions.order(date: :desc).limit(10) do |rev|
      json.(rev, :id, :characters, :views, :date, :url)
      json.article do
        json.title full_title(rev.article)
        json.url article_url(rev.article)
      end
    end
  end
end
