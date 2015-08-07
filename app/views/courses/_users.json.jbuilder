json.users course.courses_users.eager_load(:user) do |cu|
  json.(cu, :character_sum_ms, :character_sum_us, :role)
  json.(cu.user, :id, :wiki_id, :trained, :contribution_url)
  json.admin cu.user.permissions == 1

  if user_signed_in? && current_user.role(course) > 0
    json.real_name cu.user.real_name
  end
end
