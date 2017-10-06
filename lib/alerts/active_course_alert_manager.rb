# frozen_string_literal: true

class ActiveCourseAlertManager
  def initialize(courses)
    @courses = courses
  end

  def create_alerts
    @courses.each do |course|
      next unless moderate_productivity?(course)
      next if Alert.exists?(course_id: course.id, type: 'ActiveCourseAlert')
      alert = Alert.create(type: 'ActiveCourseAlert',
                           course_id: course.id,
                           target_user_id: communications_manager&.id)
      alert.email_target_user
    end
  end

  private

  MIN_AVERAGE_WORDS_PER_USER = 400
  def moderate_productivity?(course)
    course.average_word_count > MIN_AVERAGE_WORDS_PER_USER
  end

  def communications_manager
    SpecialUsers.communications_manager
  end
end
