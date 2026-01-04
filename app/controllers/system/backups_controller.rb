# frozen_string_literal: true
require 'sidekiq/api'

module System
  class BackupsController < ApplicationController
    respond_to :json

    def can_start_backup
      # The WorkSet stores the work being done by this Sidekiq cluster.
      # This is live data that can change every millisecond.
      # Used to determine wether there are any jobs currently running.
      if Sidekiq::WorkSet.new.size.positive?
        render json: { message: 'not_ready' }, status: :service_unavailable
      else
        render json: { message: 'ok' }
      end
    end
  end
end
