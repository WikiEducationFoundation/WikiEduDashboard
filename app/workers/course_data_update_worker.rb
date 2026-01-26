# frozen_string_literal: true
require_dependency "#{Rails.root}/app/services/update_course_stats"

class CourseDataUpdateWorker
  THIRTY_DAYS = 60 * 60 * 24 * 30
  include Sidekiq::Worker
  include Sidekiq::Status::Worker
  sidekiq_options lock: :until_and_while_executing,
                  lock_ttl: THIRTY_DAYS,
                  retry: 0 # Move job to the 'dead' queue if it fails

  def self.update_course(course_id:, queue:)
    CourseDataUpdateWorker.set(queue:).perform_async(course_id)
  end

  def perform(course_id)
    store(jid:,
          worker: self.class.name,
          arguments: [course_id],
          phase: 'initialization')
    sidekiq_status_logger = LogSidekiqStatus.new(method(:store))
    course = Course.find(course_id)
    logger.info "Ignoring #{course.slug} update" if course.very_long_update?
    return if course.very_long_update?

    logger.info "Updating course timeslice version: #{course.slug}"
    UpdateCourseStats.new(course, sidekiq_status_logger:)
  rescue StandardError => e
    Sentry.capture_exception e
  end
end
