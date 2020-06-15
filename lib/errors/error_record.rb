# frozen_string_literal: true

class ErrorRecord
  attr_reader :error, :sentry_extra, :level
  attr_writer :level

  def initialize(error, sentry_extra, update_service: nil)
    @error = error
    @sentry_extra = sentry_extra
    @update_service = update_service
    @level = nil
  end

  def specific_error_logging?
    @update_service.present?
  end

  def log_error
    @update_service.log_error(self)
  end
end
