class UpdateLog

  def self.log_update(time)
    setting = Setting.find_or_create_by(key: 'metrics_update')
    setting.value["last_update"] = time
    setting.save
  end

  def self.last_update
    Setting.find_by(key: 'metrics_update') ? Setting.find_by(key: 'metrics_update').value['last_update'].strftime("%H:%M:%S - %d/%m/%Y") : 0
  end
end

# 