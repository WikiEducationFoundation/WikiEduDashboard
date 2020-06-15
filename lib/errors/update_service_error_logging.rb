# frozen_string_literal: true

module UpdateServiceErrorLogging
  def sentry_tag_uuid
    @sentry_tag_uuid ||= SecureRandom.uuid
  end

  def error_count
    @error_count ||= 0
  end

  def log_error(error_record)
    @error_count = error_count + 1
    report_course_exception_sentry(error_record)
  end

  def report_course_exception_sentry(error_record)
    Raven.capture_exception(error_record.error,
                            level: error_record.level,
                            extra: error_record.sentry_extra,
                            tags: {
                              update_service_id: sentry_tag_uuid,
                              course: @course.slug
                            })
  end
end
