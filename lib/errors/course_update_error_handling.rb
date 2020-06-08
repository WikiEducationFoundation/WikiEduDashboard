# frozen_string_literal: true

module CourseUpdateErrorHandling
  def perform_course_error_handling(error_record)
    error_record.sentry_tag_uuid = SecureRandom.uuid
    save_course_error_record(error_record)
    report_course_exception_sentry(error_record)
  end

  def save_course_error_record(error_record)
    modify_extra_data(error_record)
    # WikiApi uses a gem which abstracts the url from us, so we only store
    # api_call_url in the case of Replica and OresApi
    CourseErrorRecord.create(course: error_record.course,
                             type_of_error: error_record.error.class,
                             sentry_tag_uuid: error_record.sentry_tag_uuid,
                             api_call_url: error_record.course_extra[:url],
                             miscellaneous: error_record.course_extra[:miscellaneous])
  end

  def report_course_exception_sentry(error_record)
    Raven.tags_context(uuid: error_record.sentry_tag_uuid) do
      Raven.capture_exception(error_record.error,
                              level: error_record.level,
                              extra: error_record.sentry_extra)
    end
  end

  # Modifying course_extra data for Replica and OresApi which require
  # response body for Oj::ParseError to be saved in CourseErrorRecord
  # WikiApi does not have Oj::ParseError as a typical error, which is
  # why it does not use this method
  def modify_extra_data(error_record)
    # Does processing only if course_extra[:build] is true, which is
    # true for Replica and OresApi
    return unless error_record.course_extra[:build]
    result = { url: error_record.course_extra[:url] }
    if error_record.error.class == Oj::ParseError
      # First 500 characters of response_body sufficient to analyze the error.
      # In most cases of Oj::ParseError, the response is not a JSON object
      result[:miscellaneous] = { response_body: error_record.course_extra[:response_body][0..499] }
    end
    error_record.course_extra = result
  end
end
