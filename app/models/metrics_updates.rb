class MetricsUpdates

  def self.metrics
    Setting.find_or_create_by(key: 'metrics_update').value
  end

  # def self.update_metrics(key, time)
  #   setting = Setting.find_or_create_by(key: 'metrics_update')
  #   metric = setting.value
  #   metric[key] = time
  #   setting.value = metric
  #   setting.save
  # end

  def self.last_update(time)
    setting = Setting.find_or_create_by(key: 'metrics_update')
    setting.value["last_update"] = time
    setting.save
  end

end