# frozen_string_literal: true

show_email_and_real_name = user_signed_in? && current_user.role(course).positive?

json.users course.courses_users.eager_load(:user, :course) do |cu|
  json.call(cu, :character_sum_ms, :character_sum_us, :character_sum_draft, :role,
            :recent_revisions, :content_expert, :program_manager, :contribution_url, :sandbox_url)
  json.call(cu.user, :id, :username)
  json.admin cu.user.permissions == User::Permissions::ADMIN

  unless Features.disable_training?
    ctp_manager = CourseTrainingProgressManager.new(cu.user, cu.course)
    json.course_training_progress ctp_manager.course_training_progress
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
