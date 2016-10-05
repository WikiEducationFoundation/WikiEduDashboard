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

  def self.disable_onboarding?
    ENV['disable_onboarding'] == 'true'
  end

  def self.disable_help?
    ENV['disable_help'] == 'true'
  end

  def self.disable_training?
    ENV['disable_training'] == 'true'
  end

  def self.disable_wiki_output?
    ENV['disable_wiki_output'] == 'true'
  end

  def self.open_course_creation?
    ENV['open_course_creation'] == 'true'
  end

  def self.enable_legacy_courses?
    ENV['enable_legacy_courses'] == 'true'
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

  def self.enable_revision_feedback?
    Rails.env != 'production'
  end
end
