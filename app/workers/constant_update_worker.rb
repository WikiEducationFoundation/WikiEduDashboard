# frozen_string_literal: true
require_dependency Rails.root.join('lib/data_cycle/constant_update')

class ConstantUpdateWorker
  include Sidekiq::Worker
  sidekiq_options lock: :until_executed

  def perform
    ConstantUpdate.new
  end
end
