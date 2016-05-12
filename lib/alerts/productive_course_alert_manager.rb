class ProductiveCourseAlertManager
  def initialize(courses)
    @courses = courses
  end

  def create_alerts
    @courses.each do |course|
      next if course.user_count == 0
      next if Alert.exists?(course_id: course.id, type: 'ProductiveCourseAlert')
      next unless high_average_productivity?(course)
      alert = Alert.create(type: 'ProductiveCourseAlert', course_id: course.id)
      alert.email_course_admins
    end
  end

  private

  MIN_AVERAGE_WORDS_PER_USER = 800
  def high_average_productivity?(course)
    average_words_per_user = course.word_count / course.user_count
    average_words_per_user > MIN_AVERAGE_WORDS_PER_USER
  end
end
