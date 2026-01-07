# frozen_string_literal: true
class BackupPauseMiddleware
  def call(worker, job, queue)
    return if skippable?(worker) && Backup.in_process?

    yield
  end

  def skippable?(worker)
    worker.class.respond_to?(:skippable_during_backup?) &&
      worker.class.skippable_during_backup?
  end
end

Sidekiq.configure_server do |config|
  config.server_middleware do |chain|
    chain.add BackupPauseMiddleware
  end
end
