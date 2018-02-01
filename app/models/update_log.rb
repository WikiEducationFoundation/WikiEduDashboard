# frozen_string_literal: true

class UpdateLog
  ####################
  # CONSTANTS        #
  ####################
  # We want to keep a maximum number of 10 updates, so the last key we want to save is the ninth
  MAX_UPDATES_KEY = 9

  def log_updates(times)
    add_new_log(times)
    delete_old_log
    log_delay
    save_setting
  end

  def updates
    return unless setting_record.value['constant_update']
    { 'last_update' => setting_record.value['constant_update'].values.last['end_time'],
      'average_delay' => setting_record.value['average_delay'] }
  end

  def setting_record
    @setting ||= Setting.find_or_create_by(key: 'metrics_update')
  end

  private

  def add_new_log(times)
    setting_record.value['constant_update'] ||= {}
    @last_update = setting_record.value['constant_update'].keys.last
    this_update = @last_update ? @last_update + 1 : 0

    setting_record.value['constant_update'][this_update] = times
  end

  def delete_old_log
    return unless @last_update&. >= MAX_UPDATES_KEY
    setting_record.value['constant_update'].delete(@last_update - MAX_UPDATES_KEY)
  end

  def log_delay
    constant_update = @setting.value['constant_update']
    return unless constant_update&.length&. > 1
    times = constant_update.values.map { |log| log['end_time'] }
    average_delay_in_seconds = (times.last.to_f - times.first.to_f) / (times.count - 1)
    @setting.value['average_delay'] = average_delay_in_seconds.to_i
  end

  def save_setting
    @setting.save
  end
end
