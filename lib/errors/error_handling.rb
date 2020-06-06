# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/errors/course_update_error_handling"

module ErrorHandling
  include CourseUpdateErrorHandling

  def perform_error_handling(error:, extra:, course:, optional_params:)
    Rails.logger.info "Caught #{error}"
    level = error_level(error)
    if course.present?
      perform_course_error_handling(error: error, level: level, extra: extra,
                                    course: course, optional_params: optional_params)
    else
      report_exception_sentry(error, level, extra)
    end
    return nil
  end

  def error_level(error)
    self.class.const_get(:TYPICAL_ERRORS).include?(error.class) ? 'warning' : 'error'
  end

  def raise_unexpected_error(error)
    raise error if self.class.const_get(:TYPICAL_ERRORS).exclude?(error.class)
  end

  def report_exception_sentry(error, level, extra)
    Raven.capture_exception error, level: level, extra: extra
  end
end
