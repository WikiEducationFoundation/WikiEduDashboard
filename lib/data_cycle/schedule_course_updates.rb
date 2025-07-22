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
    log_latency_messages
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
    course_ids_to_skip = course_ids_for_ongoing_updates

    courses_to_update.each do |course|
      next if course_ids_to_skip.include? course.id

      queue = queue_for(course)
      log_message "Set course #{course.slug} to queue #{queue}"
      CourseDataUpdateWorker.update_course(course_id: course.id, queue:)

      # if course isn't updated before, add first update flags
      next if course.flags[:first_update] || course.flags['update_logs']
      first_update = first_update_flags(course)
      course.flags[:first_update] = first_update
      course.save
    end
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

  def course_ids_for_ongoing_updates
    course_ids = []
    current_jobs = Sidekiq::WorkSet.new
    # Each job in the WorkSet is an array that looks something like this:
    # ["peony-sidekiq-medium:997699:0a5ebc4b7c42",
    # "js0f",
    # {"queue"=>"medium_update",
    #   "payload"=>
    #   {"retry"=>0,
    #     "queue"=>"medium_update",
    #     "lock"=>"until_executed",
    #     "lock_ttl"=>2592000,
    #     "args"=>[31480],
    #     "class"=>"CourseDataUpdateWorker",
    #     "jid"=>"1e9eafe911dbd521ad2a2928",
    #     "created_at"=>1743516909.464536,
    #     "sentry_trace"=>"87b06a7fed374e9ea31a5e47eab39457-a5e9c95dad13287c-0",
    #     "lock_timeout"=>0,
    #     "lock_prefix"=>"uniquejobs",
    #     "lock_args"=>[31480],
    #     "lock_digest"=>"uniquejobs:929a711942186a4f20887ca9129b715f",
    #     "enqueued_at"=>1743516909.468488},
    #   "run_at"=>1743538518}]
    current_jobs.each do |_process_id, _thread_id, job_args|
      job_class = job_args.dig('payload', 'class')
      next unless job_class == 'CourseDataUpdateWorker'
      course_ids += job_args.dig('payload', 'args')
    end

    course_ids
  end
end
