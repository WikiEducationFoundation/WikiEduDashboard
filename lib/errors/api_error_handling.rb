# frozen_string_literal: true

module ApiErrorHandling
  def log_error(error_record)
    Rails.logger.info "Caught #{error_record.error}"
    error_record.level = error_level(error_record.error)
    if error_record.specific_error_logging?
      error_record.log_error
    else
      report_exception_sentry(error_record)
    end
    return nil
  end

  def error_level(error)
    self.class.const_get(:TYPICAL_ERRORS).include?(error.class) ? 'warning' : 'error'
  end

  def raise_unexpected_error(error)
    raise error if self.class.const_get(:TYPICAL_ERRORS).exclude?(error.class)
  end

  def report_exception_sentry(error_record)
    Raven.capture_exception(error_record.error,
                            level: error_record.level,
                            extra: error_record.sentry_extra)
  end
end
