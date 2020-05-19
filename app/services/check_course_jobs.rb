# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/data_cycle/course_queue_sorting"

# Utility for debugging problems with the course update job queue.
class CheckCourseJobs
  include CourseQueueSorting

  def initialize(course)
    @course = course
    @course_id = course.id
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
      'queue' => queue_for(@course),
      'unique_args' => [@course_id]
    }.to_json
    digest = OpenSSL::Digest::MD5.hexdigest hash
    "uniquejobs:#{digest}"
  end

  def find_job
    Sidekiq::Queue.all.each do |queue|
      queue.each do |job|
        next unless job.klass == 'CourseDataUpdateWorker'
        return job if job.args == [@course_id]
      end
    end

    return nil
  end
end
