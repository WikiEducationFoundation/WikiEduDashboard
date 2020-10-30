# frozen_string_literal: true

class SandboxedCourseMainspaceMonitor
  def self.create_alerts_for_active_courses
    new.create_alerts_for_active_courses
  end

  def initialize
    @courses = Course.strictly_current.select(&:stay_in_sandbox?)
  end

  def create_alerts_for_active_courses
    @courses.each do |course|
      next unless nontrivial_mainspace_activity?(course)
      next if Alert.exists?(course_id: course.id, type: 'SandboxedCourseMainspaceAlert')
      alert = Alert.create(type: 'SandboxedCourseMainspaceAlert',
                           course_id: course.id)
      alert.email_content_expert
    end
  end

  private

  MAX_WORDS_PER_ARTICLE = 100
  def nontrivial_mainspace_activity?(course)
    most_words_added_to_article(course) > MAX_WORDS_PER_ARTICLE
  end

  def most_words_added_to_article(course)
    WordCount.from_characters(course.articles_courses.pluck(:character_sum).max || 0)
  end
end
