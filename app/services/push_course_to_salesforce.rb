# frozen_string_literal: true
require "#{Rails.root}/lib/word_count"

#= Pushes course data to Salesforce, either by creating a new record or updating an existing one
class PushCourseToSalesforce
  attr_reader :result

  def initialize(course)
    return unless Features.wiki_ed?
    @course = course
    @salesforce_id = @course.flags[:salesforce_id]
    @client = Restforce.new
    push
  end

  private

  def push
    if @salesforce_id
      update_salesforce_record
    else
      create_salesforce_record
    end
  end

  def create_salesforce_record
    # :create returns the Salesforce id of the new record
    @salesforce_id = @client.create!('Course__c', course_salesforce_fields)
    @course.flags[:salesforce_id] = @salesforce_id
    @course.save
    @result = @salesforce_id
  end

  def update_salesforce_record
    @result = @client.update!('Course__c', { Id: @salesforce_id }.merge(course_salesforce_fields))
  # When Salesforce API is unavailable, it returns an HTML response that causes
  # a parsing error.
  rescue Faraday::ParsingError => e
    Raven.capture_exception e
  end

  def course_salesforce_fields
    {
      # NOTE: Course name in Salesforce is sometimes modified to include term for
      # courses on the quarter system. We need to find a new convention for documenting
      # quarter system terms before including course name in the synced data.
      # Name: @course.title,
      Course_Page__c: @course.url,
      Course_Dashboard__c: "https://#{ENV['dashboard_url']}/courses/#{@course.slug}",
      Program__c: program_id,
      Estimated_No_of_Participants__c: @course.expected_students,
      Articles_edited__c: @course.article_count,
      Total_edits__c: @course.revision_count,
      Words_added_in_thousands__c: words_added_in_thousands,
      Actual_No_of_Participants__c: @course.user_count
    }
  end

  def program_id
    case @course.type
    when 'ClassroomProgramCourse'
      ENV['SF_CLASSROOM_PROGRAM_ID']
    when 'VisitingScholarship'
      ENV['SF_VISITING_SCHOLARS_PROGRAM_ID']
    end
  end

  def words_added_in_thousands
    WordCount.from_characters(@course.character_sum).to_f / 1000
  end
end
