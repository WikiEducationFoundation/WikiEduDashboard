# frozen_string_literal: true
require_dependency Rails.root.join('lib/data_cycle/schedule_course_updates')

class ScheduleCourseUpdatesWorker
  include Sidekiq::Worker
  sidekiq_options lock: :until_executed

  def perform
    ScheduleCourseUpdates.new
  end
end
