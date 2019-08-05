# frozen_string_literal: true

class SalesforceSyncWorker
  include Sidekiq::Worker
  sidekiq_options unique: :until_executed

  def perform
    Course.current.each do |course|
      next unless course.flags[:salesforce_id]
      PushCourseToSalesforce.new(course)
    end
    ClassroomProgramCourse
      .archived
      .where(withdrawn: false)
      .reject(&:closed?)
      .select(&:approved?).each do |course|
      UpdateCourseFromSalesforce.new(course)
    end
  end
end
