# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/data_cycle/update_logger"

module CheckCourseJobsLogging
  def log_orphan_record
    Raven.capture_message('Orphan lock removed',
                          level: 'warn',
                          extra: sentry_extra)
    return nil
  end

  def log_previous_failed_update(removal_time)
    UpdateLogger.update_course(@course, 'orphan_lock_failure' => removal_time.to_datetime)
  end

  def sentry_extra
    { course: @course.slug, queue: @queue }
  end
end
