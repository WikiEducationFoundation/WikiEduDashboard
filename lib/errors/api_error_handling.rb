# frozen_string_literal: true

module ApiErrorHandling
  def log_error(error, update_service: nil, sentry_extra: nil, new_errors: nil)
    Rails.logger.info "Caught #{error}"
    sentry_tags = nil
    if update_service.present?
      sentry_tags = update_service.sentry_tags
      update_service.new_errors_count = new_errors
      update_service.update_error_stats
    end
    Sentry.capture_exception(error,
                             level: error_level(error),
                             extra: sentry_extra,
                             tags: sentry_tags)
    return nil
  end

  def error_level(error)
    self.class.const_get(:TYPICAL_ERRORS).include?(error.class) ? 'warning' : 'error'
  end
end
