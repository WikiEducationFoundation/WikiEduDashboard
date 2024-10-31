# frozen_string_literal: true

module ApiErrorHandling
  def log_error(error, update_service: nil, sentry_extra: nil)
    Rails.logger.info "Caught #{error}"
    sentry_tags = nil
    if update_service.present?
      new_errors_count = sentry_extra&.dig(:new_errors_count) || 1
      update_service.update_error_stats(new_errors_count)
      sentry_tags = update_service.sentry_tags
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
