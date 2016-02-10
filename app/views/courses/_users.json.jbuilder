json.users course.courses_users.eager_load(:user) do |cu|
  ctp_manager = CourseTrainingProgressManager.new(cu.user, cu.course)
  json.call(cu, :character_sum_ms, :character_sum_us, :role)
  json.call(cu.user, :id, :wiki_id, :contribution_url, :sandbox_url)
  json.admin cu.user.permissions == User::Permissions::ADMIN
  json.recent_revisions RevisionStat.recent_revisions_for_user_and_course(cu.user, cu.course).count
  if !ENV['disable_training']
    json.course_training_progress ctp_manager.course_training_progress
  end
  json.modules_overdue ctp_manager.first_overdue_module.present?

  if user_signed_in? && current_user.role(course) > 0
    json.real_name cu.user.real_name
    json.email cu.user.email
  end
end
