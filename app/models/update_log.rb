class UpdateLog
  ####################
  # CONSTANTS        #
  ####################
  MAX_UPDATES_TO_KEEP = 10

  def self.setting_record
    Setting.find_or_create_by(key: 'metrics_update')
  end

  def self.log_updates(starttime, endtime)
    self.add_new_log
    self.update_data(starttime, endtime)
    self.log_delay
  end

  def self.average_delay
    setting = self.setting_record
    setting.value['average_delay'] ? setting.value['average_delay']: nil
  end

  def self.last_update
    setting = self.setting_record
    setting.value['constant_update'] ? setting.value['constant_update'].values.last['end_time'] : nil
  end

  private 

    def self.add_new_log
      setting = self.setting_record
      if setting.value['constant_update'] === nil
        setting.value['constant_update'] = Hash.new
        setting.save
      end
    end

    def self.update_data(starttime, endtime)
      setting = self.setting_record
      last_update = setting.value['constant_update'].keys.last
      if last_update === nil
        index = 0 
      elsif last_update >= MAX_UPDATES_TO_KEEP 
        setting.value['constant_update'].delete(last_update - MAX_UPDATES_TO_KEEP)
        index = last_update + 1
      else 
        index = last_update + 1
      end
      setting.value['constant_update'][index] = {'start_time' => starttime, 'end_time' => endtime}
      setting.save
    end

    def self.log_delay
      setting = self.setting_record
      constant_update = setting.value['constant_update']
      if constant_update 
        seconds = constant_update.keys.length > 1 ? constant_update.map {|key, value| (Time.parse(constant_update[key]["end_time"].to_s) - Time.parse(constant_update[key-1]["end_time"].to_s) if key != constant_update.keys[0]).to_i} : [0]
        setting.value['average_delay'] = seconds.inject(:+)/(seconds.length-1) if seconds.length > 1
        setting.save
      end
    end

end