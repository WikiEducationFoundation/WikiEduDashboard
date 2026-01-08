# frozen_string_literal: true
require 'sidekiq/api'

module System
  class BackupsController < ApplicationController
    respond_to :json

    def can_start_backup
      current_backup = Backup.current_backup

      # There should always be a backup record before starting the backup.
      return render_not_ready if current_backup.nil?

      # The WorkSet stores the work being done by this Sidekiq cluster.
      # This is live data that can change every millisecond.
      # It's only safe to run a backup if all running jobs started
      # after the backup was scheduled.
      ready = Sidekiq::WorkSet.new.all? do |_process_id, _thread_id, work|
        Time.zone.at(work['run_at']).to_datetime > current_backup.created_at + 1.minute
      end

      ready ? render_ok : render_not_ready
    end

    private

    def render_ok
      render json: { message: 'ok' }
    end

    def render_not_ready
      render json: { message: 'not_ready' }, status: :service_unavailable
    end
  end
end
