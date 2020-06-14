# frozen_string_literal: true

module CourseUpdateErrorHandling
  def sentry_tag_uuid
    @sentry_tag_uuid ||= SecureRandom.uuid
  end

  def perform_error_handling(error_record)
    update_course_flags
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

  def update_course_flags
    @course.flags[:errors] ||= {}
    @course.flags[:errors][sentry_tag_uuid] ||= 0
    @course.flags[:errors][sentry_tag_uuid] += 1
    @course.save
  end
end
