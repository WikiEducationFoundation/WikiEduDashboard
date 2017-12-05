# frozen_string_literal: true

class UnsubmittedCourseAlertManager
  def create_alerts
    unsubmitted_recently_started_courses.each do |course|
      next if Alert.exists?(course_id: course.id,
                            type: 'UnsubmittedCourseAlert')

      alert = Alert.create(type: 'UnsubmittedCourseAlert',
                           course: course,
                           user: course.instructors.first,
                           target_user: alert_recipient(course))
      alert.email_target_user
    end
  end

  private

  DAYS_AGO_LIMIT = 30
  def unsubmitted_recently_started_courses
    ClassroomProgramCourse.unsubmitted.where(start: DAYS_AGO_LIMIT.days.ago..Date.today)
  end

  # First time instructors work with the Outreach Manager.
  # Returning instructors work with the Classroom Program Manager.
  def alert_recipient(course)
    if course.tag? 'first_time_instructor'
      SpecialUsers.outreach_manager
    else # 'returning_instructor', and fallback just in case a course has neither tag.
      SpecialUsers.classroom_program_manager
    end
  end
end
