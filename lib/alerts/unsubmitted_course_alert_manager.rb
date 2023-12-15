# frozen_string_literal: true

class UnsubmittedCourseAlertManager
  def create_alerts
    unsubmitted_recently_created_courses.each do |course|
      next if Alert.exists?(course_id: course.id,
                            type: 'UnsubmittedCourseAlert')

      alert = Alert.create(type: 'UnsubmittedCourseAlert',
                           course:,
                           user: course.instructors.first)
      alert.send_email
    end
  end

  private

  # If a course goes a week after creation without being submitted, we send an email.
  TIME_AFTER_CREATION = 1.week
  # When we start sending out pings, we don't want to send them for older ones that
  # were for previous terms.
  MAX_TIME_AFTER_CREATION = 3.months
  def unsubmitted_recently_created_courses
    ClassroomProgramCourse.unsubmitted
                          .where('courses.created_at <= ?', TIME_AFTER_CREATION.ago)
                          .where('courses.created_at >= ?', MAX_TIME_AFTER_CREATION.ago)
  end
end
