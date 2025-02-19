# frozen_string_literal: true

class UpdateDebugger
  def initialize(course)
    @course = course
  end

  def log_update_progress(step)
    return unless debug?
    @sentry_logs ||= {}
    @log_number ||= 0
    # Add the log number to the step name so that the records are sorted
    ordered_step = "#{@log_number}_#{step}".to_sym
    @sentry_logs[ordered_step] = Time.zone.now
    @log_number += 1
    Sentry.capture_message "#{@course.title} update: #{step}",
                           level: 'warning',
                           extra: { logs: @sentry_logs }
  end

  def debug?
    @course.flags[:debug_updates]
  end
end
