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
      status: queue.size.zero? ? 'No pending jobs' : 'Pending jobs',
      latency: convert_latency(queue.latency)
    }
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
      sub_unit_value = (remaining_seconds / (unit / 60)).to_i
      result += " #{sub_unit_value} #{sub_unit_name}#{'s' unless sub_unit_value == 1}"
    end
    result
  end
end
