# frozen_string_literal: true

class UpdateLog
  ####################
  # CONSTANTS        #
  ####################
  # We want to keep a maximum number of 10 updates, so the last key we want to save is the ninth
  MAX_UPDATES_KEY = 9

  def self.log_updates(starttime, endtime)
    add_new_log(starttime, endtime)
    delete_old_log
    log_delay
    save_setting
  end

  def self.average_delay
    return unless setting_record.value['average_delay']
    setting_record.value['average_delay']
  end

  def self.last_update
    return unless setting_record.value['constant_update']
    setting_record.value['constant_update'].values.last['end_time']
  end

  class << self
    def setting_record
      @setting ||= Setting.find_or_create_by(key: 'metrics_update')
    end

    def add_new_log(starttime, endtime)
      setting_record.value['constant_update'] ||= {}

      @last_update = setting_record.value['constant_update'].keys.last
      if @last_update === nil
        index = 0
      else
        index = @last_update + 1
      end
      setting_record.value['constant_update'][index] = {
        'start_time' => starttime,
        'end_time' => endtime
      }
    end

    def delete_old_log
      return unless @last_update&. >= MAX_UPDATES_KEY
      setting_record.value['constant_update'].delete(@last_update - MAX_UPDATES_KEY)
    end

    def log_delay
      constant_update = @setting.value['constant_update']
      return unless constant_update&.keys&.length&. > 1
      times = constant_update.map { |key, value| Time.parse(value['end_time'].to_s) }
      seconds = (times[times.length - 1] - times[0]) / (times.length - 1)
      @setting.value['average_delay'] = seconds
    end

    def save_setting
      @setting.save
    end
  end
end
