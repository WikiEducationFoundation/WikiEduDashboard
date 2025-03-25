# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/data_cycle/batch_update_logging"
require_dependency "#{Rails.root}/lib/data_cycle/course_queue_sorting"
require_dependency "#{Rails.root}/app/workers/course_data_update_worker"
require_dependency "#{Rails.root}/app/workers/update_wikidata_stats_worker"

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
  # These are very reliable, so no need to log the successful ones.
  # log_end_of_update 'Schedule course updates finished.'

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

    log_message "Courses to update #{courses_to_update.map(&:slug).join(', ')}"

    courses_to_update.each do |course|
      queue = queue_for(course)
      log_message "Set course #{course.slug} to queue #{queue}"
      CourseDataUpdateWorker.update_course(course_id: course.id, queue:)

      # if course isn't updated before, add first update flags
      next if course.flags[:first_update] || course.flags['update_logs']
      first_update = first_update_flags(course)
      course.flags[:first_update] = first_update
      course.save
    end

    log_latency_messages
  end

  def latency(queue)
    Sidekiq::Queue.new(queue).latency
  end

  def log_latency_messages
    log_message "Short update latency: #{latency('short_update')}"
    log_message "Medium update latency: #{latency('medium_update')}"
    log_message "Long update latency: #{latency('long_update')}"
  end

  def first_update_flags(course)
    {
      enqueued_at: Time.zone.now,
      queue_name: queue_for(course),
      queue_latency: latency(queue_for(course))
    }
  end
end
