# frozen_string_literal: true

#= Enables chat features for a course and adds all participants to course chat channel
class PushCourseToSalesforce
  attr_reader :result

  def initialize(course)
    return unless Features.wiki_ed?
    @course = course
    @client = Restforce.new
    create_salesforce_record
  end

  private

  def create_salesforce_record
    @result = @client.create('Course__c', course_salesforce_fields)
  end

  def course_salesforce_fields
    {
      Name: @course.title,
      Course_Page__c: @course.url,
      Course_Dashboard__c: "https://#{ENV['dashboard_url']}/courses/#{@course.slug}"
    }
  end
end
