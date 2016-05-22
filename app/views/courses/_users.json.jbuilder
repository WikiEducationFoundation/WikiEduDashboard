show_email_and_real_name = user_signed_in? && current_user.role(course) > 0

json.users course.courses_users.eager_load(:user) do |cu|
  json.call(cu, :character_sum_ms, :character_sum_us, :role, 
                :content_expert, :program_manager)
  json.call(cu.user, :id, :username, :contribution_url, :sandbox_url)
  json.admin cu.user.permissions == User::Permissions::ADMIN
  json.recent_revisions RevisionStat.recent_revisions_for_user_and_course(cu.user, cu.course).count

  unless Features.disable_training?
    ctp_manager = CourseTrainingProgressManager.new(cu.user, cu.course)
    json.course_training_progress ctp_manager.course_training_progress
    json.modules_overdue ctp_manager.first_overdue_module.present?
  end

  # Email and real names of participants are only shown to admins or
  # an instructor of the course.
  # Emails and names of greeters are shown to all users
  if show_email_and_real_name || cu.user.greeter
    json.real_name cu.user.real_name
    # Student emails are not shown to anyone.
    json.email cu.user.email unless cu.role == CoursesUsers::Roles::STUDENT_ROLE
  end
end
