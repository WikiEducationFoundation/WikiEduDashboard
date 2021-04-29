# frozen_string_literal: true
require_dependency "#{Rails.root}/lib/data_cycle/daily_update"

class DailyUpdateWorker
  include Sidekiq::Worker
  sidekiq_options unique: :until_executed

  def perform
    DailyUpdate.new
  end
end
