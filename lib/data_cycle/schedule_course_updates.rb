# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/data_cycle/batch_update_logging"
require_dependency "#{Rails.root}/app/workers/course_data_update_worker"

# Executes all the steps of 'update_constantly' data import task
class ScheduleCourseUpdates
  include BatchUpdateLogging

  def initialize
    setup_logger
    return if updates_paused?
    return if conflicting_updates_running?

    run_update_with_pid_files(:short)
  end

  private

  def run_update
    log_start_of_update 'Schedule course updates starting.'
    enqueue_course_updates
    log_end_of_update 'Schedule course updates finished.'
  # rubocop:disable Lint/RescueException
  rescue Exception => e
    log_end_of_update 'Schedule course updates failed.'
    raise e
  end
  # rubocop:enable Lint/RescueException

  ###############
  # Data import #
  ###############

  def enqueue_course_updates
    log_message "Ready to update #{Course.ready_for_update.count} courses"
    Course.ready_for_update.each do |course|
      CourseDataUpdateWorker.update_course(course_id: course.id, queue: queue_for(course))
    end
    log_message "Short update latency: #{latency('short_update')}"
    log_message "Medium update latency: #{latency('medium_update')}"
    log_message "Long update latency: #{latency('long_update')}"
  end

  def conflicting_updates_running?
    return true if update_running?(:short)
    false
  end

  def queue_for(course)
    course_length = course.end - course.start
    not_ended = Time.zone.now < course.end
    if course_length < 3.days && not_ended
      'short_update'
    elsif course_length < 6.months
      'medium_update'
    else
      'long_update'
    end
  end

  def latency(queue)
    Sidekiq::Queue.new(queue).latency
  end
end
