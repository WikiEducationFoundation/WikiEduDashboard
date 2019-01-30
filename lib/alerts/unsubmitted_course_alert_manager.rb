# frozen_string_literal: true

class UnsubmittedCourseAlertManager
  def create_alerts
    unsubmitted_recently_started_courses.each do |course|
      next if Alert.exists?(course_id: course.id,
                            type: 'UnsubmittedCourseAlert')

      alert = Alert.create(type: 'UnsubmittedCourseAlert',
                           course: course,
                           user: course.instructors.first)
      alert.email_target_user
    end
  end

  private

  TIME_WINDOW = 3
  def unsubmitted_recently_started_courses
    ClassroomProgramCourse.unsubmitted
                          .where('courses.created_at <= ?', TIME_WINDOW.days.ago)
                          .where('courses.start <= ?', TIME_WINDOW.days.from_now)
  end
end
