class NewRelicQueueLatencyLogger
  def call(worker, job, queue)
    queue_latency = Time.now.utc - Time.at(job["enqueued_at"], in: "+00:00")
    info = {
      queue_latency: queue_latency,
      queue: queue,
    }
    if worker.class.to_s == "CourseDataUpdateWorker"
      info[:course_id] = job["args"][0]
    end
    ::NewRelic::Agent.add_custom_attributes(info)
    yield
  end
end

Sidekiq.configure_server do |config|
  config.server_middleware do |chain|
    chain.add NewRelicQueueLatencyLogger
  end
end
