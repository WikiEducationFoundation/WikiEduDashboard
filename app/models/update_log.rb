class UpdateLog

  def self.setting_record
    Setting.find_or_create_by(key: 'metrics_update')
  end

  def self.log_update(time)
    setting = self.setting_record
    setting.value["last_update"] = time
    setting.save
  end

  def self.last_update
    self.setting_record
    Setting.find_by(key: 'metrics_update').value['last_update']
  end
end