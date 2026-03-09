# frozen_string_literal: true
require 'sidekiq/api'

module System
  class BackupsController < ApplicationController
    respond_to :json

    COURSE_UPDATE_WORKER_CLASS = CourseDataUpdateWorker.name

    def can_start_backup
      # There should always be a backup record before starting the backup.
      return render_not_ready if Backup.current_backup.nil?

      # The WorkSet stores the work being done by this Sidekiq cluster.
      # This is live data that can change every millisecond.
      # It's only safe to run a backup if all running jobs have
      # phase status set to sleeping
      ready = Sidekiq::WorkSet.new.all? do |_process_id, _thread_id, work|
        payload = work['payload']
        jid = payload['jid']

        status = Sidekiq::Status.get_all(jid)

        # Non-CourseDataUpdateWorker jobs are irrelevant for backup safety.
        next true unless payload['class'] == COURSE_UPDATE_WORKER_CLASS

        # CourseDataUpdateWorker without sidekiq-status is unexpected
        # (likely expired), so we log and block the backup.
        if status.empty?
          log_missing_status(jid)
          next false
        end

        course_data_update_worker_sleeping?(status)
      end

      ready ? render_ok : render_not_ready
    end

    private

    def log_missing_status(jid)
      Sentry.capture_message("#{COURSE_UPDATE_WORKER_CLASS} without sidekiq-status",
                             level: 'error',
                             extra: { jid: jid })
    end

    def course_data_update_worker_sleeping?(status)
      status['worker'] == 'CourseDataUpdateWorker' && status['phase'].include?('sleeping')
    end

    def render_ok
      render json: { message: 'ok' }
    end

    def render_not_ready
      render json: { message: 'not_ready' }, status: :service_unavailable
    end
  end
end
