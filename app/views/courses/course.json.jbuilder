# frozen_string_literal: true

json.course do
  user_role = current_user&.role(@course) || CoursesUsers::Roles::VISITOR_ROLE

  json.call(@course, :id, :title, :description, :start, :end, :school,
            :subject, :slug, :url, :submitted, :expected_students, :timeline_start,
            :timeline_end, :day_exceptions, :weekdays, :no_day_exceptions,
            :updated_at, :string_prefix, :use_start_and_end_times, :type,
            :home_wiki, :upload_count, :uploads_in_use_count, :upload_usages_count,
            :cloned_status, :flags, :level)

  json.timeline_enabled @course.timeline_enabled?
  json.term @course.cloned_status == 1 ? '' : @course.term
  json.legacy @course.legacy?
  json.ended !current?(@course) && @course.start < Time.zone.now
  json.published CampaignsCourses.exists?(course_id: @course.id)
  json.enroll_url "#{request.base_url}#{course_slug_path(@course.slug)}/enroll/"

  json.created_count number_to_human @course.new_article_count
  json.edited_count number_to_human @course.article_count
  json.edit_count number_to_human @course.revision_count
  json.student_count @course.user_count
  json.trained_count @course.trained_count
  json.word_count number_to_human @course.word_count
  json.view_count number_to_human @course.view_sum
  json.syllabus @course.syllabus.url if @course.syllabus.file?
  json.last_update UpdateLog.last_update

  if user_role.zero? # student role
    ctpm = CourseTrainingProgressManager.new(current_user, @course)
    json.incomplete_assigned_modules ctpm.incomplete_assigned_modules
  end

  if user_role >= 0 # user enrolled in course
    json.survey_notifications(current_user.survey_notifications.active) do |notification|
      if notification.course.id == @course.id
        json.id notification.id
        json.survey_url course_survey_url(notification).to_s
        json.message notification.survey_assignment.custom_banner_message
      end
    end
  end

  if user_role.positive? # non-student role
    json.passcode_required @course.passcode_required?
    json.passcode @course.passcode
    json.canUploadSyllabus true
  elsif @course.passcode
    # If there is a passcode, send a placeholder value. If not, send empty string.
    json.passcode @course.passcode.blank? ? '' : '****'
    json.canUploadSyllabus false
  end
end
