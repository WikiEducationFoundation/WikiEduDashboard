# frozen_string_literal: true

module CourseUpdateErrorHandling
  def perform_error_handling(error_record)
    report_course_exception_sentry(error_record)
  end

  def report_course_exception_sentry(error_record)
    Raven.capture_exception(error_record.error,
                            level: error_record.level,
                            extra: error_record.sentry_extra,
                            tags: {
                              course_update_id: sentry_tag_uuid,
                              course: @course.slug
                            })
  end
end
