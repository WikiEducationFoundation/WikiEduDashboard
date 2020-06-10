# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/errors/course_update_error_handling"

module ErrorHandling
  include CourseUpdateErrorHandling

  def perform_error_handling(error_record)
    Rails.logger.info "Caught #{error_record.error}"
    error_record.level = error_level(error_record.error)
    if error_record.course_present?
      report_course_exception_sentry(error_record)
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
