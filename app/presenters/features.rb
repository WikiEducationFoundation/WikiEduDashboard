# frozen_string_literal: true

class Features
  # Add methods which you want to be true for the respective configurations

  PE = %i[
    disable_help? disable_onboarding? wiki_trainings?
    enable_language_switcher? enable_account_requests?
    disable_wiki_output? enable_article_finder? open_course_creation?
  ].freeze

  WIKI_ED = %i[
    enable_get_help_button?
    wiki_ed?
  ].freeze

  is_ed = ENV['wiki_education'] == 'true'

  PE.each do |method|
    define_singleton_method method do
      return false if is_ed
      true
    end
  end

  WIKI_ED.each do |method|
    define_singleton_method method do
      return true if is_ed
      false
    end
  end

  def self.default_course_type
    ENV['default_course_type'] || 'ClassroomProgramCourse'
  end

  def self.default_course_string_prefix
    default_course_type.constantize.new.string_prefix
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
