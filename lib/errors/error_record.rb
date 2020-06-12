# frozen_string_literal: true

class ErrorRecord
  attr_reader :error, :sentry_extra, :level
  attr_writer :level

  def initialize(error, sentry_extra, update_obj: nil)
    @error = error
    @sentry_extra = sentry_extra
    @update_obj = update_obj
    @level = nil
  end

  def specific_error_tasks?
    @update_obj.present?
  end

  def perform_error_handling
    @update_obj.perform_error_handling(self)
  end
end
