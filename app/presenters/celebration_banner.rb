# frozen_string_literal: true

#= Presenter for managing celebration banners (holidays, special events, etc.)
class CelebrationBanner
  VISIBILITY_OPTIONS = {
    'disabled' => 'disabled',
    'all_users' => 'all_users',
    'logged_in' => 'logged_in',
    'admins_only' => 'admins_only'
  }.freeze

  CELEBRATION_TYPES = {
    'christmas' => {
      name: 'Christmas & New Year',
      start_date: -> { Date.new(Time.zone.today.year, 12, 1) },
      end_date: -> { Date.new(Time.zone.today.year, 12, 31) },
      message: 'Happy Holidays! Wishing you a joyful Christmas & New Year',
      emoji: ['🎄', '✨']
    },
    'new_year' => {
      name: 'New Year',
      start_date: -> { Date.new(Time.zone.today.year, 12, 31) },
      end_date: -> { Date.new(Time.zone.today.year + 1, 1, 7) },
      message: 'Happy New Year! Wishing you a successful year ahead',
      emoji: ['🎉', '✨']
    },
    'generic' => {
      name: 'Generic Celebration',
      start_date: -> { Time.zone.today },
      end_date: -> { Time.zone.today + 30.days },
      message: 'Celebrating with you!',
      emoji: ['🎊', '✨']
    }
  }.freeze

  def self.setting
    Setting.find_or_create_by(key: 'celebration_banner')
  end

  def self.get
    Features.celebration_banner
  end

  def self.update(params)
    setting.update(value: params)
    Rails.cache.delete('celebration_banner')
  end

  def self.default_settings
    {
      'enabled' => Rails.env.development?,
      'visibility' => Rails.env.development? ? 'all_users' : 'disabled',
      'celebration_type' => 'christmas',
      'custom_message' => '',
      'custom_emoji' => [],
      'show_snowfall' => true,
      'auto_hide_after_seconds' => 7
    }
  end

  def self.current_celebration
    settings = get
    return nil unless settings['enabled']

    celebration_type = settings['celebration_type'] || 'christmas'
    celebration = CELEBRATION_TYPES[celebration_type]
    return nil unless celebration
    return nil unless within_date_range?(celebration)

    build_celebration_hash(celebration_type, celebration, settings)
  end

  def self.within_date_range?(celebration)
    start_date = celebration[:start_date].call
    end_date = celebration[:end_date].call
    today = Time.zone.today
    today >= start_date && today <= end_date
  end

  def self.build_celebration_hash(celebration_type, celebration, settings)
    show_snowfall = extract_boolean_setting(settings, 'show_snowfall', default: true)

    {
      type: celebration_type,
      name: celebration[:name],
      message: settings['custom_message'].presence || celebration[:message],
      emoji: settings['custom_emoji'].presence || celebration[:emoji],
      show_snowfall: show_snowfall,
      auto_hide_after_seconds: settings['auto_hide_after_seconds'] || 7
    }
  end

  def self.extract_boolean_setting(settings, key, default: false)
    if settings.key?(key)
      ActiveModel::Type::Boolean.new.cast(settings[key])
    else
      default
    end
  end

  def self.should_show?(user: nil)
    celebration = current_celebration
    return false unless celebration

    visibility = get['visibility'] || 'disabled'
    check_visibility(visibility, user)
  end

  def self.check_visibility(visibility, user)
    case visibility
    when 'disabled'
      false
    when 'all_users'
      true
    when 'logged_in'
      user.present?
    when 'admins_only'
      user&.admin?
    end
  end
end
