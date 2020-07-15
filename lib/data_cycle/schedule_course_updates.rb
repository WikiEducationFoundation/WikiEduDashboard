# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/data_cycle/batch_update_logging"
require_dependency "#{Rails.root}/lib/data_cycle/course_queue_sorting"
require_dependency "#{Rails.root}/app/workers/course_data_update_worker"
require_dependency "#{Rails.root}/app/services/check_course_jobs"

# Executes all the steps of 'update_constantly' data import task
class ScheduleCourseUpdates
  include BatchUpdateLogging
  include CourseQueueSorting

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

    courses_to_update = Course.ready_for_update
    orphan_lock_count = CheckCourseJobs.remove_orphan_locks(courses_to_update)

    courses_to_update.each do |course|
      CourseDataUpdateWorker.update_course(course_id: course.id, queue: queue_for(course))
    end
    log_message "Short update latency: #{latency('short_update')}"
    log_message "Medium update latency: #{latency('medium_update')}"
    log_message "Long update latency: #{latency('long_update')}"
    log_message "#{orphan_lock_count} Orphan lock(s) removed"
  end

  def conflicting_updates_running?
    return true if update_running?(:short)
    false
  end

  def latency(queue)
    Sidekiq::Queue.new(queue).latency
  end
end
