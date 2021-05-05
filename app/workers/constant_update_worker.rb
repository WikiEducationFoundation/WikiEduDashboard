# frozen_string_literal: true
require_dependency "#{Rails.root}/lib/data_cycle/constant_update"

class ConstantUpdateWorker
  include Sidekiq::Worker

  def perform
    ConstantUpdate.new
  end
end
