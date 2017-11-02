class MetricsUpdates

  def self.last_update(time)
    setting = Setting.find_or_create_by(key: 'metrics_update')
    setting.value["last_update"] = time
    setting.save
  end

end