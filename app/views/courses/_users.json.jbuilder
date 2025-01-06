# frozen_string_literal: true

show_email_and_real_name = user_signed_in? && current_user.can_see_real_names?(course)

json.users course.courses_users.eager_load(:user, :course) do |cu|
  json.call(cu, :character_sum_ms, :character_sum_us, :character_sum_draft, :references_count,
            :role, :role_description, :recent_revisions, :content_expert, :program_manager,
            :contribution_url, :sandbox_url, :total_uploads)
  json.call(cu.user, :id, :username)
  json.enrolled_at cu.created_at
  json.admin cu.user.admin?
  json.registered_at cu.user.registered_at

  exercise_progress = cu.course.training_progress_manager.course_exercise_progress(cu.user)
  if exercise_progress.is_a?(Hash)
    json.course_exercise_progress_description exercise_progress[:description]
    json.course_exercise_progress_assigned_count exercise_progress[:assigned_count]
    json.course_exercise_progress_completed_count exercise_progress[:completed_count]
  end

  training_progress = cu.course.training_progress_manager.course_training_progress(cu.user)
  if training_progress.is_a?(Hash)
    json.course_training_progress_description training_progress[:description]
    json.course_training_progress_assigned_count training_progress[:assigned_count]
    json.course_training_progress_completed_count training_progress[:completed_count]
  end

  # Email and real names of participants are only shown to admins or
  # an instructor of the course.
  # Emails and names of greeters are shown to all users
  if show_email_and_real_name || cu.user.greeter
    json.real_name cu.real_name
    # Student emails are not shown to anyone.
    json.email cu.user.email unless cu.role == CoursesUsers::Roles::STUDENT_ROLE
  # Real names of instructors are public.
  elsif cu.role == CoursesUsers::Roles::INSTRUCTOR_ROLE
    json.real_name cu.real_name
  end
end
