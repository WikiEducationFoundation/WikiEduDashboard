# frozen_string_literal: true

class Features
  def self.wiki_ed?
    ENV['wiki_education'] == 'true'
  end

  def self.staging?
    ENV['dashboard_url'] == 'dashboard-testing.wikiedu.org'
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

  def self.disable_wiki_output?
    ENV['disable_wiki_output'] == 'true'
  end

  def self.open_course_creation?
    ENV['wiki_education'] != 'true'
  end

  def self.default_course_type
    wiki_ed? ? 'ClassroomProgramCourse' : 'BasicCourse'
  end

  def self.default_course_string_prefix
    @default_course_string_prefix ||= default_course_type.constantize.new.string_prefix
  end

  def self.hot_loading?
    ENV['hot_loading'] == 'true'
  end

  def self.sentry?
    ENV['hot_loading'] != 'true' && ENV['DISABLE_SENTRY'] != 'true'
  end

  def self.email?
    !ENV['mailgun_key'].nil?
  end

  def self.site_notice
    Rails.cache.fetch('site_notice') do
      site_notice = Setting.find_by(key: 'site_notice')&.value.presence || {}
      site_notice
    end
  end

  def self.celebration_banner
    Rails.cache.fetch('celebration_banner') do
      celebration_banner = Setting.find_by(key: 'celebration_banner')&.value.presence
      celebration_banner || {
        'enabled' => Rails.env.development?,
        'visibility' => Rails.env.development? ? 'all_users' : 'disabled',
        'celebration_type' => 'christmas',
        'custom_message' => '',
        'custom_emoji' => [],
        'show_snowfall' => false,
        'auto_hide_after_seconds' => 7
      }
    end
  end
end
