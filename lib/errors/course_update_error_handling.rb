# frozen_string_literal: true

module CourseUpdateErrorHandling
  def perform_course_error_handling(error, level, extra, course, optional_params)
    sentry_tag_uuid = SecureRandom.uuid
    save_course_error_record(course, error, sentry_tag_uuid, optional_params)
    report_course_exception_sentry(error, level, extra, sentry_tag_uuid)
  end

  def save_course_error_record(course, error, sentry_tag_uuid, optional_params)
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
end
