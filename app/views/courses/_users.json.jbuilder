json.users course.courses_users do |cu|
  json.(cu, :character_sum_ms, :character_sum_us, :role)
  json.(cu.user, :id, :wiki_id, :trained, :contribution_url)
  json.admin cu.user.permissions == 1

  if user_signed_in? && current_user.role(course) > 0
    json.real_name cu.user.real_name
  end

  if cu.role == 0
    json.revisions cu.user.revisions.order(date: :desc).limit(10) do |rev|
      json.(rev, :id, :characters, :views, :date, :url)
      json.article do
        if rev.article.nil?
          json.title 'Deleted article'
          json.url nil
        else
          json.title full_title(rev.article)
          json.url article_url(rev.article)
        end
      end
    end
  end
end
