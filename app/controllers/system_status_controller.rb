# frozen_string_literal: true

class SystemStatusController < ApplicationController
  def index
    system_metrics = SystemMetrics.new

    @sidekiq_stats = system_metrics.fetch_sidekiq_stats
    @queue_metrics = system_metrics.fetch_queue_management_metrics
  end
end
