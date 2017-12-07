class UpdateLog

  def self.setting_record
    Setting.find_or_create_by(key: 'metrics_update')
  end

  def self.last_update
    setting = self.setting_record
    setting.value.values.last

  end

  def self.log_updates(time)
    setting = self.setting_record
    last_update = setting.value.keys.last
    if last_update === nil
      new_update = 0
    elsif last_update >= 10
      setting.value.delete(last_update - 10)
      new_update = last_update + 1
    else 
      new_update = last_update + 1
    end
    setting.value[new_update] = time
    setting.save
  end

  def self.average_delay
    setting = self.setting_record
    seconds = setting.value.map {|key, value| (Time.parse(setting.value[key].to_s) - Time.parse(setting.value[key-1].to_s) if key != setting.value.keys[0]).to_i}
    seconds.inject(:+)/(seconds.length-1) if seconds.length > 1 
  end

end