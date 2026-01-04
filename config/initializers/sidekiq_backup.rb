class BackupPauseMiddleware
  RESCHEDULE_DELAY = 1.hour

  def call(worker, job, queue)
    if Backup.in_process?
      worker.class.perform_in(RESCHEDULE_DELAY, *job['args'])
      return
    end

    yield
  end
end

Sidekiq.configure_server do |config|
  config.server_middleware do |chain|
    chain.add BackupPauseMiddleware
  end
end
