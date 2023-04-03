# frozen_string_literal: true
require_dependency Rails.root.join('lib/data_cycle/daily_update')

class DailyUpdateWorker
  include Sidekiq::Worker

  def perform
    DailyUpdate.new
  end
end
