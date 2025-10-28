# frozen_string_literal: true

class UpdateLogger
  ################
  # Entry points #
  ################
  def self.update_course(course, new_logs)
    course.reload if course.respond_to?(:reload)

    logs = course.flags['update_logs']
    updater = new(logs)
    updated_logs = updater.update(new_logs)
    course.flags['update_logs'] = updated_logs
    course.flags['average_update_delay'] = average_delay(updated_logs)
    course.flags['unfinished_update_logs'] =
      updater.delete_unfinished_log(new_logs, course.flags['unfinished_update_logs'])
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

  def self.number_of_constant_updates
    setting = Setting.find_or_create_by(key: 'metrics_update')
    logs = setting.value['constant_update']
    logs&.keys&.max || 0
  end

  def self.update_course_with_unfinished_update(course, new_logs)
    course.reload if course.respond_to?(:reload)

    logs = course.flags['unfinished_update_logs']
    updated_logs = new(logs).update(new_logs)
    course.flags['unfinished_update_logs'] = updated_logs
    course.save
  end

  ###########
  # Helpers #
  ###########

  def self.average_delay(log_hash)
    end_times = log_hash.values.filter_map { |log| log['end_time'] }
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

  # Deletes the unfinished_update_logs record for start_time since the update did finish.
  def delete_unfinished_log(new_logs, unfinished_logs)
    return if unfinished_logs.nil?
    unfinished_logs.delete_if do |_, log|
      log['start_time'] == new_logs['start_time']
    end
  end
end
