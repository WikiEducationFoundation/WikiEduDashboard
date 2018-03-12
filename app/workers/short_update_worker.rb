# frozen_string_literal: true
require_dependency "#{Rails.root}/lib/data_cycle/short_update"

class ShortUpdateWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'short_update'
  sidekiq_options unique: :until_executed

  def perform
    ShortUpdate.new
  end
end
