# frozen_string_literal: true
require_dependency "#{Rails.root}/lib/analytics/campaign_csv_builder"
require_dependency "#{Rails.root}/lib/analytics/course_csv_builder"
require_dependency "#{Rails.root}/lib/analytics/course_uploads_csv_builder"
require_dependency "#{Rails.root}/lib/analytics/course_students_csv_builder"
require_dependency "#{Rails.root}/lib/analytics/course_articles_csv_builder"
require_dependency "#{Rails.root}/lib/analytics/course_wikidata_csv_builder"
require_dependency "#{Rails.root}/app/controllers/reports_controller"
require_dependency "#{Rails.root}/app/workers/csv_cleanup_worker"
require_dependency "#{Rails.root}/lib/analytics/all_courses_and_instructors_csv_builder"

class ReportCsvWorker
  include Sidekiq::Worker
  sidekiq_options lock: :until_executed

  # Generate the csv for the given source (course or campaign)
  # if type is global, then can access source as nil
  def self.generate_csv(source:, filename:, type:, include_course:)
    perform_async(source&.id, filename, type, include_course)
  end

  def perform(id, filename, type, include_course)
    data =
      if type == 'all_courses_and_instructors'
        all_courses_and_instructors_csv
      elsif course_report?(type)
        to_course_csv(type, id)
      else
        to_campaign_csv(type, id, include_course)
      end

    write_csv(filename, data)
    CsvCleanupWorker.perform_at(1.week.from_now, filename)
  end

  def to_campaign_csv(type, campaign_id, include_course)
    campaign = Campaign.find(campaign_id)
    builder = CampaignCsvBuilder.new(campaign)

    case type
    when 'campaign_instructors'
      campaign.users_to_csv(:instructors, course: include_course)
    when 'campaign_students'
      campaign.users_to_csv(:students, course: include_course)
    when 'campaign_courses'
      builder.courses_to_csv
    when 'campaign_articles'
      builder.articles_to_csv
    when 'campaign_wikidata'
      builder.wikidata_to_csv
    end
  end

  def to_course_csv(type, course_id)
    course = Course.find(course_id)
    case type
    when 'course_overview'
      CourseCsvBuilder.new(course, per_wiki: true).generate_csv
    when 'course_editors'
      CourseStudentsCsvBuilder.new(course).generate_csv
    when 'course_uploads'
      CourseUploadsCsvBuilder.new(course).generate_csv
    when 'course_articles'
      CourseArticlesCsvBuilder.new(course).generate_csv
    when 'course_wikidata'
      CourseWikidataCsvBuilder.new(course).generate_csv
    end
  end

  def all_courses_and_instructors_csv
    AllCoursesAndInstructorsCsvBuilder.new.generate_csv
  end

  private

  def write_csv(filename, data)
    FileUtils.mkdir_p "public#{ReportsController::CSV_PATH}"
    File.write "public#{ReportsController::CSV_PATH}/#{filename}", data
  end

  def course_report?(type)
    type.start_with?('course')
  end
end
