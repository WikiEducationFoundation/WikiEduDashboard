# frozen_string_literal: true

module CourseUpdateErrorHandling
  def report_course_exception_sentry(error_record)
    Raven.capture_exception(error_record.error,
                            level: error_record.level,
                            extra: error_record.sentry_extra,
                            tags: {
                              course_update_id: error_record.sentry_tag_uuid,
                              course: error_record.course_slug
                            })
  end
end
