# frozen_string_literal: true

require_dependency Rails.root.join('lib/word_count')

#= Pulls course-related data from Salesforce
class UpdateCourseFromSalesforce
  def initialize(course)
    return unless Features.wiki_ed?
    @course = course
    @salesforce_id = @course.flags[:salesforce_id]
    return unless @salesforce_id
    @client = Restforce.new(SalesforceCredentials.get)
    update
  rescue StandardError => e
    Sentry.capture_exception e
  end

  private

  def salesforce_record
    @salesforce_record ||= @client.find('Course__c', @salesforce_id)
  end

  def update
    @course.flags[:closed_date] = salesforce_record['Course_Closed_Date__c']
    @course.save
  end
end
