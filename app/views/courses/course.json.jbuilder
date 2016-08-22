json.course do
  user_role = if current_user
                current_user.role(@course)
              else
                -1
              end

  json.call(@course, :id, :title, :description, :start, :end, :school,
            :subject, :slug, :url, :listed, :submitted, :listed,
            :expected_students, :timeline_start, :timeline_end, :day_exceptions,
            :weekdays, :no_day_exceptions, :updated_at, :string_prefix, :type, :home_wiki)

  json.term @course.cloned_status == 1 ? '' : @course.term
  json.legacy @course.legacy?
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
  json.syllabus @course.syllabus.url if @course.syllabus.file?

  if user_role == 0 # student role
    ctpm = CourseTrainingProgressManager.new(current_user, @course)
    json.incomplete_assigned_modules ctpm.incomplete_assigned_modules
  end

  if user_role >= 0 # user enrolled in course
    json.survey_notifications(current_user.survey_notifications.active) do |notification|
      if notification.course.id == @course.id
        json.id notification.id
        json.survey_url course_survey_url(notification).to_s
      end
    end
  end

  if user_role > 0 # non-student role
    json.passcode @course.passcode
    json.canUploadSyllabus true
  elsif @course.passcode
    json.passcode '****'
    json.canUploadSyllabus false
  end
end
