# frozen_string_literal: true

class ContinuedCourseActivityAlertManager
  def initialize(courses)
    @courses = courses
  end

  def create_alerts
    @courses.each do |course|
      next if Alert.exists?(course_id: course.id,
                            type: 'ContinuedCourseActivityAlert',
                            resolved: false)

      next if course.students.empty?

      next unless significant_activity_after_course_end?(course)

      alert = Alert.create(type: 'ContinuedCourseActivityAlert', course_id: course.id)
      alert.email_content_expert
    end
  end

  private

  MINIMUM_CHARACTERS_ADDED_AFTER_COURSE_END = 1000
  def significant_activity_after_course_end?(course)
    user_ids = course.students.pluck(:id)
    post_course_characters = Revision
                             .where(user_id: user_ids)
                             .where('date > ?', course.end.end_of_day)
                             .joins(:article)
                             .where(articles: { namespace: Article::Namespaces::MAINSPACE })
                             .sum(:characters)
    post_course_characters > MINIMUM_CHARACTERS_ADDED_AFTER_COURSE_END
  end
end
