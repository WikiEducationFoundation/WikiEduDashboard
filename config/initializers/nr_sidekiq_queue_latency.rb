class NewRelicQueueLatencyLogger
  def call(worker, job, queue)
    queue_latency = Time.now.utc - Time.at(job["enqueued_at"], in: "+00:00")
    ::NewRelic::Agent.add_custom_attributes({ queue_latency: queue_latency, queue: queue })
    yield
  end
end

Sidekiq.configure_server do |config|
  config.server_middleware do |chain|
    chain.add NewRelicQueueLatencyLogger
  end
end