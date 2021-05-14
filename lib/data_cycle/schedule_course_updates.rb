# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/data_cycle/batch_update_logging"
require_dependency "#{Rails.root}/lib/data_cycle/course_queue_sorting"
require_dependency "#{Rails.root}/app/workers/course_data_update_worker"

# Puts courses into sidekiq queues for data updates
class ScheduleCourseUpdates
  include BatchUpdateLogging
  include CourseQueueSorting

  def initialize
    setup_logger
    return if updates_paused?

    run_update
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

    courses_to_update.each do |course|
      CourseDataUpdateWorker.update_course(course_id: course.id, queue: queue_for(course))
    end
    log_message "Short update latency: #{latency('short_update')}"
    log_message "Medium update latency: #{latency('medium_update')}"
    log_message "Long update latency: #{latency('long_update')}"
  end

  def latency(queue)
    Sidekiq::Queue.new(queue).latency
  end
end
