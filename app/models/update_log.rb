class UpdateLog
  ####################
  # CONSTANTS        #
  ####################
  MAX_UPDATES_TO_KEEP = 10

  def self.setting_record
    Setting.find_or_create_by(key: 'metrics_update')
  end

  def self.log_delay
    setting = self.setting_record
    constant_update = setting.value['constant_update']
    if constant_update 
      seconds = constant_update.keys.length > 1 ? constant_update.map {|key, value| (Time.parse(constant_update[key]["end_time"].to_s) - Time.parse(constant_update[key-1]["end_time"].to_s) if key != constant_update.keys[0]).to_i} : [0]
      setting.value['average_delay'] = seconds.inject(:+)/(seconds.length-1) if seconds.length > 1
    end
    setting.save
  end

  def self.log_updates(starttime, endtime)
    setting = self.setting_record
    update_record = setting.value['constant_update']
    if setting.value['constant_update'] === nil
      setting.value['constant_update'] = Hash.new
      index = 0 
    elsif last_update >= MAX_UPDATES_TO_KEEP 
      index = update_record.keys.last
      update_record.delete(index - MAX_UPDATES_TO_KEEP)
      index = index + 1
    else 
      index = update_record.keys.last + 1
    end
    setting.value['constant_update'][index] = {'start_time' => starttime, 'end_time' => endtime}
    setting.save
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
end