# frozen_string_literal: true

class ErrorRecord
  attr_reader :error, :sentry_extra, :level
  attr_writer :level

  def initialize(error, sentry_extra, update_object: nil)
    @error = error
    @sentry_extra = sentry_extra
    @update_object = update_object
    @level = nil
  end

  def specific_error_tasks?
    @update_object.present?
  end

  def perform_error_handling
    @update_object.perform_error_handling(self)
  end
end
