# frozen_string_literal: true

require 'sidekiq/api'

class SystemMetricsService
  def initialize
    @queues = YAML.load_file('config/sidekiq.yml')[:queues]
    fetch_sidekiq_stats
  end

  def fetch_sidekiq_stats
    stats = Sidekiq::Stats.new

    @processed_jobs_stat = stats.processed
    @failed_jobs_stat = stats.failed # Failed Job Retention
    @enqueued_jobs_stat = stats.enqueued
    @scheduled_jobs_stat = stats.scheduled_size

    # also allow stats from selected dates to be viewed
    # using Stats::History
  end

  # def fetch_system_health_metrics
  # end

  # def fetch_reliability_metrics
  # end

  # def fetch_availability_metrics
  # end

  # def fetch_processing_efficiency_metrics
  # end

  # def fetch_resource_utilization_metrics
  # end

  def fetch_queue_management_metrics
    # Queue latency; how long jobs wait in the queue before processing
    @queues.map do |queue_name|
      queue = Sidekiq::Queue.new(queue_name)
      {
        name: queue.name,
        size: queue.size,
        latency: queue.latency
      }
    end
  end

  # def fetch_data_freshness_metrics
  # end
end
