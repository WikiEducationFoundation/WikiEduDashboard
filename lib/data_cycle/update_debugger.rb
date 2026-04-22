# frozen_string_literal: true

class UpdateDebugger
  attr_reader :stage_timings

  def initialize(course)
    @course = course
    @stage_timings = {}
    @log_number = 0
  end

  def log_update_progress(step)
    ordered_step = :"#{@log_number}_#{step}"
    @stage_timings[ordered_step] = Time.zone.now
    @log_number += 1
    return unless debug?
    Sentry.capture_message "#{@course.title} update: #{step}",
                           level: 'warning',
                           extra: { logs: @stage_timings }
  end

  def debug?
    @course.flags[:debug_updates]
  end
end
