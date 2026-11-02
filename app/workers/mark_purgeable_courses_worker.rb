# frozen_string_literal: true

require_dependency "#{Rails.root}/app/services/mark_purgeable_courses"

class MarkPurgeableCoursesWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'default', retry: 0

  def perform
    result = MarkPurgeableCourses.new
    Rails.logger.info "MarkPurgeableCourses: flagged #{result.marked_count} courses as purgeable"
  end
end
