# frozen_string_literal: true

class ConnectCoursesToSalesforce
  def initialize(dry_run: false)
    @dry_run = dry_run
    @client = Restforce.new
    @courses = Course.all.select { |course| course.flags[:salesforce_id].nil? }
  end

  def call
    @courses.each do |course|
      matching_record = find_matching_salesforce_record(course)
      next if matching_record.blank?
      course.flags[:salesforce_id] = matching_record.Id
      if @dry_run
        puts course.slug
      else
        puts course.slug
        course.save
      end
    end
  end

  def find_matching_salesforce_record(course)
    search_results = search_salesforce_for(course)
    search_results.searchRecords.find do |record|
      includes_course_slug?(record, course.slug)
    end
  end

  def search_salesforce_for(course)
    # some characters are not allowed in Salesforce queries, including colon, dash, apostrophe
    sanitized_title = course.title.gsub(/[:\-\']/, '')
    @client.search('FIND {' + sanitized_title + '} RETURNING Course__c (Course_Dashboard__c, Course_Page__c, Id)')
  end

  def includes_course_slug?(record, slug)
    record_url = record.Course_Dashboard__c
    unless record_url
      record_url = record.Course_Page__c
      puts record_url
    end
    return false unless record_url
    return true if record_url.include? slug
    return true if record_url.include? CGI.escape(slug).gsub('%2F', '/')
    false
  end
end
