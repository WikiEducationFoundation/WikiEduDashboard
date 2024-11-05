# frozen_string_literal: true

class UpdateDebugger
  def initialize(course)
    @course = course
  end

  def log_update_progress(step)
    return unless debug?
    @sentry_logs ||= {}
    @sentry_logs[step] = Time.zone.now
    Sentry.capture_message "#{@course.title} update: #{step}",
                           level: 'warning',
                           extra: { logs: @sentry_logs }
  end

  def debug?
    @course.flags[:debug_updates]
  end
end
