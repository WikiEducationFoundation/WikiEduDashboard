# frozen_string_literal: true

module CourseUpdateErrorHandling
  def perform_course_error_handling(error:, level:, extra:, course:, optional_params:)
    sentry_tag_uuid = SecureRandom.uuid
    save_course_error_record(course, error, sentry_tag_uuid, optional_params)
    report_course_exception_sentry(error, level, extra, sentry_tag_uuid)
  end

  def save_course_error_record(course, error, sentry_tag_uuid, optional_params)
    optional_params = build_optional_params(error, optional_params)
    # WikiApi uses a gem which abstracts the url from us, so we only store
    # api_call_url in the case of Replica and OresApi
    CourseErrorRecord.create(course: course,
                             type_of_error: error.class,
                             sentry_tag_uuid: sentry_tag_uuid,
                             api_call_url: optional_params[:url],
                             miscellaneous: optional_params[:miscellaneous])
  end

  def report_course_exception_sentry(error, level, extra, sentry_tag_uuid)
    Raven.tags_context(uuid: sentry_tag_uuid) do
      Raven.capture_exception error, level: level, extra: extra
    end
  end

  # Building optional params for Replica and OresApi which require
  # response body for Oj::ParseError to be saved in CourseErrorRecord
  # WikiApi does not have Oj::ParseError as a typical error, which is
  # why it does not use this method
  def build_optional_params(error, optional_params)
    # Does processing only if optional_params[:build] is true, which is
    # true for Replica and OresApi
    return optional_params unless optional_params[:build] == true
    result = { url: optional_params[:url] }
    if error.class == Oj::ParseError
      # First 500 characters of response_body sufficient to analyze the error.
      # In most cases of Oj::ParseError, the response is not a JSON object
      result[:miscellaneous] = { response_body: optional_params[:response_body][0..499] }
    end
    result
  end
end
