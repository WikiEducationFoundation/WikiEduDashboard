# frozen_string_literal: true

require 'sidekiq/api'

class GetSystemMetrics
  def initialize
    @queues = YAML.load_file('config/sidekiq.yml')[:queues]
                  .reject { |queue_name| queue_name == 'very_long_update' }
    fetch_sidekiq_stats
  end

  def fetch_sidekiq_stats
    stats = Sidekiq::Stats.new
    {
      enqueued_jobs: stats.enqueued,
      active_jobs: stats.processes_size
    }
  end

  def fetch_queue_management_metrics
    queues = []
    paused_queues = []
    all_operational = true

    @queues.each do |queue_name|
      queue = Sidekiq::Queue.new(queue_name)
      queues << get_queue_data(queue)

      if queue.paused?
        all_operational = false
        paused_queues << queue_name
      end
    end

    {
      queues:,
      paused_queues:,
      all_operational:
    }
  end

  def get_queue_data(queue)
    {
      name: queue.name,
      size: queue.size,
      status: get_queue_status(queue.name, queue.latency),
      latency: convert_latency(queue.latency)
    }
  end

  def get_queue_status(queue_name, latency)
    latency_thresholds = {
      'default' => 1,
      'short_update' => 2.hours,
      'medium_update' => 12.hours,
      'long_update' => 1.day,
      'daily_update' => 1.day,
      'constant_update' => 15.minutes
    }
    threshold = latency_thresholds[queue_name]

    latency < threshold ? 'Normal' : 'Backlogged'
  end

  def convert_latency(seconds)
    case seconds
    when 0...60
      "#{seconds.to_i} second#{'s' unless seconds == 1}"
    when 60...3600
      format_time(seconds, 60, 'minute', 'second')
    when 3600...86400
      format_time(seconds, 3600, 'hour', 'minute')
    else
      format_time(seconds, 86400, 'day', 'hour')
    end
  end

  def format_time(seconds, unit, main_unit_name, sub_unit_name)
    main_unit = (seconds / unit).to_i
    remaining_seconds = (seconds % unit).to_i
    result = "#{main_unit} #{main_unit_name}#{'s' unless main_unit == 1}"
    if remaining_seconds.positive?
      sub_unit, sub_unit_name = case main_unit_name
                                when 'day'
                                  [3600, 'hour']
                                when 'hour'
                                  [60, 'minute']
                                else
                                  [1, 'second']
                                end
      sub_unit_value = (remaining_seconds / sub_unit).to_i
      result += " #{sub_unit_value} #{sub_unit_name}#{'s' unless sub_unit_value == 1}"
    end
    result
  end
end
