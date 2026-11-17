# frozen_string_literal: true

# Runs PushCourseApplicationToSalesforce in the background, so a slow or failing
# Salesforce never holds up an applicant or a decision. Sidekiq retries a
# failure; the ids the push saves keep a retry from duplicating records.
class PushCourseApplicationToSalesforceWorker
  include Sidekiq::Worker
  sidekiq_options lock: :until_executed

  # Each application to a course just linked to Salesforce.
  def self.push_course(course)
    course.course_applications.pluck(:id).each { |id| perform_async(id) }
  end

  def perform(application_id)
    application = CourseApplication.find_by(id: application_id)
    # Deleted since it was queued.
    return unless application

    PushCourseApplicationToSalesforce.new(application)
  end
end
