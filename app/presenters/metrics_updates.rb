class MetricsUpdates

  def self.metrics
    Setting.find_or_create_by(key: 'metrics_update').value
  end

  def self.update_metrics
    Setting.find_or_create_by(key: 'metrics_update').value["last_update"] = Rails.cache.read("last_update")
  end

 end