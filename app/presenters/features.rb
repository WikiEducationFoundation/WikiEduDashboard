# frozen_string_literal: true

class Features
  # This is for toggling Wiki Ed-specific features that should not be active
  # on any other dashboard instances.
  def self.wiki_ed?
    return true if ENV['dashboard_url'] == 'dashboard.wikiedu.org'
    return true if ENV['dashboard_url'] == 'dashboard-testing.wikiedu.org'
    false
  end

  def self.default_course_type
    ENV['default_course_type'] || 'ClassroomProgramCourse'
  end

  def self.default_course_string_prefix
    default_course_type.constantize.new.string_prefix
  end

  def self.disable_onboarding?
    ENV['disable_onboarding'] == 'true'
  end

  def self.disable_help?
    ENV['disable_help'] == 'true'
  end

  def self.disable_wiki_output?
    ENV['disable_wiki_output'] == 'true'
  end

  def self.open_course_creation?
    ENV['open_course_creation'] == 'true'
  end

  def self.enable_article_finder?
    ENV['enable_article_finder'] == 'true'
  end

  def self.hot_loading?
    ENV['hot_loading'] == 'true'
  end

  def self.email?
    !ENV['SENDER_EMAIL_ADDRESS'].nil?
  end

  def self.enable_get_help_button?
    ENV['enable_get_help_button'] == 'true'
  end

  def self.enable_language_switcher?
    ENV['enable_language_switcher'] == 'true'
  end

  def self.wiki_trainings?
    ENV['enable_wiki_trainings'] == 'true'
  end

  # Determines whether chat is available at all within the dashboard
  def self.enable_chat?
    ENV['enable_chat'] == 'true'
  end

  # Determines whether chat is enabled for an individual course
  def self.enable_course_chat?(course)
    return false unless enable_chat?
    course.flags[:enable_chat] == true
  end
end
