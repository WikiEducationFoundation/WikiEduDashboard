# frozen_string_literal: true
require_dependency "#{Rails.root}/lib/data_cycle/schedule_course_updates"

class ScheduleCourseUpdatesWorker
  include Sidekiq::Worker
  sidekiq_options lock: :until_executed,
                  on_conflict: :replace

  def perform
    ScheduleCourseUpdates.new
  end
end
