# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/errors/course_update_error_handling"

module ErrorHandling
  include CourseUpdateErrorHandling

  def perform_error_handling(error, extra, course, optional_params)
    Rails.logger.info "Caught #{error}"
    level = error_level(error)
    if course.present?
      perform_course_error_handling(error, level, extra, course, optional_params)
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

  # Building optional params for Replica and OresApi which require
  # response body for Oj::ParseError to be saved in CourseErrorRecord
  # WikiApi does not have Oj::ParseError as a typical error, which is
  # why it does not use this method
  def build_optional_params(course, error, url, response_body)
    return {} unless course.present?
    optional_params = { url: url }
    if error.class == Oj::ParseError
      # First 500 characters of response_body sufficient to analyze the error.
      # In most cases of Oj::ParseError, the response is not a JSON object
      optional_params[:miscellaneous] = { response_body: response_body[0..499] }
    end
    optional_params
  end
end
