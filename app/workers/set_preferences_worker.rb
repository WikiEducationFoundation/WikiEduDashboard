# frozen_string_literal: true

require "#{Rails.root}/lib/wiki_preferences_manager"

class SetPreferencesWorker
  include Sidekiq::Worker
  sidekiq_options unique: :until_executed

  def self.schedule_preference_setting(user:)
    perform_async(user.id)
  end

  def perform(user_id)
    user = User.find(user_id)
    preferences_manager = WikiPreferencesManager.new(user: user)
    preferences_manager.enable_visual_editor
  end
end
