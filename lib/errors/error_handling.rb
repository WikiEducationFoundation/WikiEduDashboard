# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/errors/course_update_error_handling"

module ErrorHandling
  include CourseUpdateErrorHandling

  def perform_error_handling_tasks(error, level, extra, course, optional_params)
    return report_exception_sentry(error, level, extra) unless course.present?
    sentry_tag_uuid = SecureRandom.uuid
    save_course_error_record(course, error, sentry_tag_uuid, optional_params)
    report_exception_sentry(error, level, extra, sentry_tag_uuid: sentry_tag_uuid)
  end

  def report_exception_sentry(error, level, extra, sentry_tag_uuid: nil)
    if sentry_tag_uuid.present?
      Raven.tags_context(uuid: sentry_tag_uuid) do
        Raven.capture_exception error, level: level, extra: extra
      end
    else
      Raven.capture_exception error, level: level, extra: extra
    end
    return nil
  end
end
