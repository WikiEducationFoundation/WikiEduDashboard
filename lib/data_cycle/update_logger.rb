# frozen_string_literal: true

class UpdateLogger
  ################
  # Entry points #
  ################
  def self.update_course(course, new_logs)
    logs = course.flags['update_logs']
    updated_logs = new(logs).update(new_logs)
    course.flags['update_logs'] = updated_logs
    course.flags['average_update_delay'] = average_delay(updated_logs)
    course.save
  end

  def self.update_settings_record(times)
    setting = Setting.find_or_create_by(key: 'metrics_update')
    old_logs = setting.value['constant_update']
    new_logs = new(old_logs).update(times)
    setting.value['constant_update'] = new_logs
    setting.value['average_delay'] = average_delay(new_logs)
    setting.save
  end

  ###########
  # Helpers #
  ###########

  def self.average_delay(log_hash)
    end_times = log_hash.values.map { |log| log['end_time'] }.compact
    return unless end_times&.length&.> 1
    average_delay_in_seconds = (end_times.last.to_f - end_times.first.to_f) / (end_times.count - 1)
    average_delay_in_seconds.to_i
  end

  # We want to keep a maximum number of 10 updates
  MAX_UPDATES = 10

  def initialize(log_hash)
    @log_hash = log_hash || {}
    @last_update_number = @log_hash.keys.max || 0
  end

  def update(new_logs)
    @update_number = @last_update_number + 1
    @log_hash[@update_number] = new_logs
    @log_hash.delete(@log_hash.keys.min) until @log_hash.count <= MAX_UPDATES
    @log_hash
  end
end
