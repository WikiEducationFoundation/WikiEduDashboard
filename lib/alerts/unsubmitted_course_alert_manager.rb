# frozen_string_literal: true

class UnsubmittedCourseAlertManager
  def create_alerts
    unsubmitted_recently_started_courses.each do |course|
      next if Alert.exists?(course_id: course.id,
                            type: 'UnsubmittedCourseAlert')

      alert = Alert.create(type: 'UnsubmittedCourseAlert',
                           course: course,
                           user: course.instructors.first,
                           target_user: SpecialUsers.classroom_program_manager)
      alert.email_target_user
    end
  end

  private

  DAYS_AGO_LIMIT = 30
  def unsubmitted_recently_started_courses
    Course.unsubmitted.where(start: DAYS_AGO_LIMIT.days.ago..Date.today)
  end
end
