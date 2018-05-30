# frozen_string_literal: true

class Features
  def self.wiki_ed?
    ENV['wiki_education'] == 'true'
  end

  def self.enable_get_help_button?
    ENV['wiki_education'] == 'true'
  end

  def self.wiki_trainings?
    ENV['wiki_education'] != 'true'
  end

  def self.disable_help?
    ENV['wiki_education'] != 'true'
  end

  def self.disable_onboarding?
    ENV['wiki_education'] != 'true'
  end

  def self.enable_language_switcher?
    ENV['wiki_education'] != 'true'
  end

  def self.enable_account_requests?
    ENV['wiki_education'] != 'true'
  end

  def self.disable_wiki_output?
    ENV['disable_wiki_output'] == 'true'
  end

  def self.open_course_creation?
    ENV['wiki_education'] != 'true'
  end

  def self.default_course_type
    ENV['default_course_type'] || 'ClassroomProgramCourse'
  end

  def self.default_course_string_prefix
    @default_course_string_prefix ||= default_course_type.constantize.new.string_prefix
  end

  def self.hot_loading?
    ENV['hot_loading'] == 'true'
  end

  def self.email?
    !ENV['mailgun_key'].nil?
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

  def self.celebrate?(current_user)
    return false unless current_user&.admin?
    ENV['celebrate'] == 'true'
  end
end
