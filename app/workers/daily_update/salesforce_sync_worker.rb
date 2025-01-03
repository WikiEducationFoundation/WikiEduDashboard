# frozen_string_literal: true

class SalesforceSyncWorker
  include Sidekiq::Worker
  sidekiq_options lock: :until_executed

  def perform
    Course.current.each do |course|
      next unless course.flags[:salesforce_id]
      next unless course.approved?
      PushCourseToSalesforce.new(course)
    end
    ClassroomProgramCourse
      .ended
      .where(withdrawn: false)
      .reject(&:closed?)
      .select(&:approved?).each do |course|
      UpdateCourseFromSalesforce.new(course)
    end
  end
end
