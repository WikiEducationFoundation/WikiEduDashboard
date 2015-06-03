json.courses_users course.courses_users do |cu|
  json.(cu, :character_sum_ms, :character_sum_us, :role)
  json.user do
    json.(cu.user, :id, :wiki_id, :trained)
    json.assignments cu.user.assignments do |ass|
      json.(ass, :id, :article_title)
      json.reviewers ass.assignments_users do |au|
        json.(au.user, :wiki_id)
      end
    end
    json.revisions cu.user.revisions.order(date: :desc).limit(10) do |rev|
      json.(rev, :id, :characters, :views, :date)
      json.article rev.article, :title
    end
  end
end
