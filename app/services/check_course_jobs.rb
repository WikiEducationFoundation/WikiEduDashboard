# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/data_cycle/check_course_jobs_logging"
require_dependency "#{Rails.root}/lib/data_cycle/course_queue_sorting"

# Utility for debugging problems with the course update job queue.
class CheckCourseJobs
  include CheckCourseJobsLogging
  include CourseQueueSorting

  COURSE_DATA_UPDATE_WORKER = 'CourseDataUpdateWorker'

  def self.remove_orphan_locks(courses_to_update)
    courses_to_update.each do |course|
      new(course).delete_orphan_lock
    end
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

  def find_job
    find_scheduled_job || find_queued_job || find_active_job
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
    if !job_exists? && lock_exists?
      delete_unique_lock
      log_previous_failed_update
      log_orphan_record
      return true
    end
    return false
  end

  private

  def find_scheduled_job
    Sidekiq::ScheduledSet.new.select do |retri|
      next unless retri.klass == COURSE_DATA_UPDATE_WORKER
      return retri if retri.args == @worker_args
    end
    return nil
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
