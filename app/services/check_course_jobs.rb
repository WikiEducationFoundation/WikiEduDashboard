# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/data_cycle/check_course_jobs_logging"
require_dependency "#{Rails.root}/lib/data_cycle/course_queue_sorting"

# Utility for debugging problems with the course update job queue.
class CheckCourseJobs
  include CheckCourseJobsLogging
  include CourseQueueSorting

  COURSE_DATA_UPDATE_WORKER = 'CourseDataUpdateWorker'

  def self.remove_orphan_locks(courses_to_update)
    orphan_lock_count = 0
    courses_to_update.each do |course|
      orphan_lock_count += 1 if new(course).delete_orphan_lock
    end
    orphan_lock_count
  end

  def initialize(course)
    @course = course
    @worker_args = [course.id]
    @queue = queue_for(course)
  end

  def job_exists?
    find_job.present?
  end

  def lock_exists?
    SidekiqUniqueJobs::Digests.all.include? expected_digest
  end

  # Currently, course jobs are either enqueued, or already running
  # Course jobs are neither scheduled nor retried(retry: 0), so not searching in those sets
  def find_job
    find_queued_job || find_active_job
  end

  # This is based on the implementation of SidekiqUniqueJobs digest generation
  # as of version 6.
  # See SidekiqUniqueJobs::UniqueArgs#create_digest
  # We want to know the expected hash so that we can look for that digest
  # among the unique digests
  def expected_digest
    hash = {
      'class' => COURSE_DATA_UPDATE_WORKER,
      'queue' => @queue,
      'unique_args' => @worker_args
    }.to_json
    digest = OpenSSL::Digest::MD5.hexdigest hash
    "uniquejobs:#{digest}"
  end

  def delete_orphan_lock
    if orphan_expected? && !job_exists? && lock_exists?
      delete_unique_lock
      removal_time = Time.zone.now
      log_previous_failed_update(removal_time)
      log_orphan_record
      return true
    end
    return false
  end

  private

  # NOTE: In a orphan lock failure, the system does not log anything
  # because the job usually ends abruptly, and does not reach the end
  # of update process where we update the logs

  def orphan_expected?
    update_logs = @course.flags['update_logs']

    # Possible in a situation where there are no logs due to all being orphan failures
    return true unless update_logs.present?

    # Extracting the latest update end time by getting the last element
    # in the values of update logs which are filtered by no orphan lock logs
    last_update_times_log = update_logs&.values
                                       &.select { |element| element['orphan_lock_failure'].nil? }
                                       &.last

    # If we cannot find a log having update times means all are orphan lock logs
    return true unless last_update_times_log.present?

    # Return true only if the last update end time is bigger than last update time + one day,
    # as currently most update jobs would end in a few minutes at max
    Time.zone.now > last_update_times_log['end_time'] + 1.day
  end

  def find_queued_job
    Sidekiq::Queue.all.each do |queue|
      queue.each do |job|
        next unless job.klass == COURSE_DATA_UPDATE_WORKER
        return job if job.args == @worker_args
      end
    end
    return nil
  end

  def find_active_job
    Sidekiq::Workers.new.each do |_process_id, _thread_id, work|
      next unless work['payload']['class'] == COURSE_DATA_UPDATE_WORKER
      return work if work['payload']['args'] == @worker_args
    end
    return nil
  end

  def delete_unique_lock
    SidekiqUniqueJobs::Digests.delete_by_digest expected_digest
  end
end
