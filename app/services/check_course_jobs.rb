# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/data_cycle/course_queue_sorting"

# Utility for debugging problems with the course update job queue.
class CheckCourseJobs
  include CourseQueueSorting

  def self.remove_orphan_locks(courses_to_update)
    orphan_lock_courses = []
    courses_to_update.each do |course|
      check_course_job = new(course)
      is_removed = check_course_job.delete_orphan_lock
      orphan_lock_courses << check_course_job.sentry_extra if is_removed
    end

    orphan_lock_count = orphan_lock_courses.length
    return unless orphan_lock_count.positive?

    Raven.capture_message("#{orphan_lock_count} Orphan lock(s) removed",
                          level: 'warn',
                          extra: { courses: orphan_lock_courses })
    return nil
  end

  def initialize(course)
    @course = course
    @course_id = course.id
    @queue = queue_for(course)
  end

  def health_report
    is_locked = SidekiqUniqueJobs::Digests.all.include? expected_digest
    has_job = find_job.present?
    pp "locked: #{is_locked}"
    pp "job in queue: #{has_job}"
  end

  def delete_unique_lock
    SidekiqUniqueJobs::Digests.delete_by_digest expected_digest
  end

  # This is based on the implementation of SidekiqUniqueJobs digest generation
  # as of version 6.
  # See SidekiqUniqueJobs::UniqueArgs#create_digest
  # We want to know the expected hash so that we can look for that digest
  # among the unique digests
  def expected_digest
    hash = {
      'class' => 'CourseDataUpdateWorker',
      'queue' => @queue,
      'unique_args' => [@course_id]
    }.to_json
    digest = OpenSSL::Digest::MD5.hexdigest hash
    "uniquejobs:#{digest}"
  end

  def find_job # rubocop:disable Metrics/CyclomaticComplexity
    Sidekiq::ScheduledSet.new.select do |retri|
      next unless retri.klass == 'CourseDataUpdateWorker'
      return retri if retri.args == [@course_id]
    end

    Sidekiq::Queue.all.each do |queue|
      queue.each do |job|
        next unless job.klass == 'CourseDataUpdateWorker'
        return job if job.args == [@course_id]
      end
    end

    Sidekiq::Workers.new.each do |_process_id, _thread_id, work|
      next unless work['payload']['class'] == 'CourseDataUpdateWorker'
      return work if work['payload']['args'] == [@course_id]
    end

    return nil
  end

  def delete_orphan_lock
    if find_job.nil? && SidekiqUniqueJobs::Digests.all.include?(expected_digest)
      delete_unique_lock
      return true
    end
    return false
  end

  def sentry_extra
    { course: @course.slug, queue: @queue }
  end
end
