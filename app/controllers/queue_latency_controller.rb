# frozen_string_literal: true
class QueueLatencyController < ApplicationController
  def latency
    short = Sidekiq::Queue.new('short_update').latency
    medium = Sidekiq::Queue.new('medium_update').latency
    render json: { short: short, medium: medium }
  end
end