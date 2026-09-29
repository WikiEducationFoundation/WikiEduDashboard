# frozen_string_literal: true

require 'tempfile'
require 'zip'
require_dependency "#{Rails.root}/lib/analytics/campaign_csv_builder"
require_dependency "#{Rails.root}/lib/analytics/course_csv_builder"
require_dependency "#{Rails.root}/lib/analytics/course_uploads_csv_builder"
require_dependency "#{Rails.root}/lib/analytics/course_students_csv_builder"
require_dependency "#{Rails.root}/lib/analytics/course_articles_csv_builder"
require_dependency "#{Rails.root}/lib/analytics/course_wikidata_csv_builder"
require_dependency "#{Rails.root}/lib/analytics/retention_predictors_csv_builder"
require_dependency "#{Rails.root}/lib/analytics/report_csv_store"
require_dependency "#{Rails.root}/app/workers/csv_cleanup_worker"
require_dependency "#{Rails.root}/lib/analytics/all_courses_and_instructors_csv_builder"
require_dependency "#{Rails.root}/lib/analytics/system_csv_builder"
require_dependency "#{Rails.root}/lib/analytics/system_stats_csv_builder"

class ReportCsvWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'report_csv', lock: :until_executed

  # Generate the csv for the given source (course or campaign)
  # if type is global, then can access source as nil
  def self.generate_csv(source:, filename:, type:, include_course:, filters: {})
    perform_async(source&.id, filename, type, include_course, filters.to_json)
  end

  def perform(id, filename, type, include_course, filters_json = '{}')
    parsed_filters = JSON.parse(filters_json).symbolize_keys
    data = report_data(type, id, include_course, parsed_filters)
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

  def to_campaign_zip(campaign_id)
    campaign = Campaign.find(campaign_id)
    builder = CampaignCsvBuilder.new(campaign)
    csv_entries = campaign_zip_entries(campaign, builder)

    Tempfile.create(['campaign_zip', '.zip']) do |tempfile|
      Zip::OutputStream.open(tempfile.path) do |zip|
        csv_entries.each do |entry_name, store_name, generator|
          zip.put_next_entry(entry_name)
          zip.write(fetch_or_build_csv(store_name, generator))
        end
      end
      File.binread(tempfile.path)
    end
  end

  def campaign_zip_entries(campaign, builder)
    [
      ['students.csv', campaign_csv_name(campaign, 'campaign_students'),
       -> { campaign.users_to_csv(:students) }],
      ['students-by-course.csv',
       campaign_csv_name(campaign, 'campaign_students', course: true),
       -> { campaign.users_to_csv(:students, course: true) }],
      ['instructors-by-course.csv',
       campaign_csv_name(campaign, 'campaign_instructors', course: true),
       -> { campaign.users_to_csv(:instructors, course: true) }],
      ['courses.csv', campaign_csv_name(campaign, 'campaign_courses'),
       -> { builder.courses_to_csv }],
      ['pages-edited.csv', campaign_csv_name(campaign, 'campaign_articles'),
       -> { builder.articles_to_csv }]
    ]
  end

  def campaign_csv_name(campaign, type, course: false)
    course_segment = course ? '-with_courses' : ''
    "#{campaign.slug}-#{type}#{course_segment}-#{Time.zone.today}.csv".tr('/', '-')
  end

  def fetch_or_build_csv(filename, generator)
    return ReportCsvStore.read(filename) if ReportCsvStore.exists?(filename)

    data = generator.call
    ReportCsvStore.write(filename, data)
    CsvCleanupWorker.perform_at(1.week.from_now, filename)
    data
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
    when 'course_retention'
      RetentionPredictorsCsvBuilder.new(course).generate_csv
    end
  end

  def all_courses_and_instructors_csv
    AllCoursesAndInstructorsCsvBuilder.new.generate_csv
  end

  # System-wide CSV with dynamic filters applied.
  # Delegates to the standalone SystemCsvBuilder.
  def to_system_csv(filters)
    SystemCsvBuilder.new(filters:).generate_csv
  end

  def to_system_daily_stats_csv(filters)
    SystemStatsCsvBuilder.new(
      start_date: filters[:start_date],
      end_date: filters[:end_date]
    ).generate_csv
  end

  private

  def report_data(type, id, include_course, filters)
    if type == 'campaign_all'
      to_campaign_zip(id)
    elsif type == 'all_courses_and_instructors'
      all_courses_and_instructors_csv
    elsif type == 'system_csv'
      to_system_csv(filters)
    elsif type == 'system_daily_stats_csv'
      to_system_daily_stats_csv(filters)
    elsif course_report?(type)
      to_course_csv(type, id)
    else
      to_campaign_csv(type, id, include_course)
    end
  end

  def write_csv(filename, data)
    ReportCsvStore.write(filename, data)
  end

  def course_report?(type)
    type.start_with?('course')
  end
end
