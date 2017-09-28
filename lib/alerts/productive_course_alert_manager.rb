# frozen_string_literal: true

class ProductiveCourseAlertManager
  def initialize(courses)
    @courses = courses
  end

  def create_alerts
    @courses.each do |course|
      next unless high_average_productivity?(course)
      next if Alert.exists?(course_id: course.id, type: 'ProductiveCourseAlert')
      alert = Alert.create(type: 'ProductiveCourseAlert', course_id: course.id)
      alert.email_course_admins
    end
  end

  private

  MIN_AVERAGE_WORDS_PER_USER = 800
  def high_average_productivity?(course)
    course.average_word_count > MIN_AVERAGE_WORDS_PER_USER
  end
end
