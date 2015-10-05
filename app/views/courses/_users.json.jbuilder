json.users course.courses_users.eager_load(:user) do |cu|
  json.(cu, :character_sum_ms, :character_sum_us, :role)
  json.(cu.user, :id, :wiki_id, :trained, :contribution_url, :sandbox_url)
  json.admin cu.user.permissions == 1
  json.recent_revisions RevisionStat.recent_revisions_for_user_and_course(cu.user, cu.course).count

  if user_signed_in? && current_user.role(course) > 0
    json.real_name cu.user.real_name
    json.email cu.user.email
  end
end
