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

  # Gates the LTIAAS-mediated Canvas integration: launch endpoints,
  # NRPS/AGS sync workers, and the Block/Wizard hooks that enqueue them.
  # Default false so production stays inert until LTIAAS is registered
  # with a live Canvas instance and the env var is flipped explicitly.
  def self.canvas_integration?
    ENV['canvas_integration_enabled'] == 'true'
  end

  def self.site_notice
    Rails.cache.fetch('site_notice') do
      site_notice = Setting.find_by(key: 'site_notice')&.value.presence || {}
      site_notice
    end
  end
end
