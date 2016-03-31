json.course do
  ctpm = CourseTrainingProgressManager.new(current_user, @course)

  json.call(@course, :id, :title, :description, :start, :end, :school,
            :subject, :slug, :url, :listed, :submitted, :listed,
            :expected_students, :timeline_start, :timeline_end, :day_exceptions,
            :weekdays, :no_day_exceptions, :updated_at, :string_prefix, :type)

  json.term @course.cloned_status == 1 ? '' : @course.term
  json.legacy @course.id < 10000
  json.ended !current?(@course) && @course.start < Time.zone.now
  json.published CohortsCourses.exists?(course_id: @course.id)
  json.enroll_url "#{request.base_url}#{course_slug_path(@course.slug)}/enroll/"

  json.created_count number_to_human @course.new_article_count
  json.edited_count number_to_human @course.article_count
  json.edit_count number_to_human @course.revisions.count
  json.student_count @course.user_count
  json.trained_count @course.trained_count
  json.word_count number_to_human @course.word_count
  json.view_count number_to_human @course.view_sum

  if current_user
    json.next_upcoming_assigned_module ctpm.next_upcoming_assigned_module
    json.first_overdue_module ctpm.first_overdue_module
    json.survey_notifications(@course.survey_notifications.where(notification_dismissed: false)) do |notification|
      if notification.user.id == current_user.id
        json.id notification.id
        json.survey_url "#{survey_url(notification.survey)}?notification=#{notification.id}"
      end
    end
  end

  if user_signed_in? && current_user.role(@course) > 0
    json.passcode @course.passcode
  elsif @course.passcode
    json.passcode '****'
  end
end
