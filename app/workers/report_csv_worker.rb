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

  # Campaign reports that include private courses are cached apart from the
  # public ones, under names with this segment.
  PRIVATE_COURSES_SEGMENT = '-with_private_courses'

  # Generate the csv for the given source (course or campaign)
  # if type is global, then can access source as nil
  def self.generate_csv(source:, filename:, type:, include_course:, filters: {},
                        include_private: false)
    perform_async(source&.id, filename, type, include_course, filters.to_json, include_private)
  end

  def self.campaign_csv_name(campaign, type, course: false, include_private: false)
    slug = campaign.respond_to?(:slug) ? campaign.slug : campaign.to_s
    course_segment = course ? '-with_courses' : ''
    private_segment = include_private ? PRIVATE_COURSES_SEGMENT : ''
    "#{slug}-#{type}#{course_segment}#{private_segment}-#{Time.zone.today}.csv".tr('/', '-')
  end

  def self.campaign_zip_name(campaign, include_private: false)
    slug = campaign.respond_to?(:slug) ? campaign.slug : campaign.to_s
    private_segment = include_private ? PRIVATE_COURSES_SEGMENT : ''
    "#{slug}-campaign-data#{private_segment}-#{Time.zone.today}.zip".tr('/', '-')
  end

  def perform(id, filename, type, include_course, filters_json = '{}', include_private = false)
    parsed_filters = JSON.parse(filters_json).symbolize_keys
    if type == 'campaign_all'
      write_campaign_zip(id, filename, include_private:)
    else
      data = report_data(type, id, include_course, parsed_filters, include_private:)
      write_csv(filename, data)
    end
    CsvCleanupWorker.perform_at(1.week.from_now, filename)
  end

  def write_campaign_zip(campaign_id, filename, include_private: false)
    Tempfile.create(['campaign_zip', '.zip']) do |tempfile|
      tempfile.close
      stream_campaign_zip(campaign_id, tempfile.path, include_private:)
      write_csv(filename, tempfile)
    end
  end

  def to_campaign_csv(type, campaign_id, include_course, include_private: false)
    campaign = Campaign.find(campaign_id)
    builder = CampaignCsvBuilder.new(campaign, include_private:)

    case type
    when 'campaign_instructors'
      campaign.users_to_csv(:instructors, course: include_course, include_private:)
    when 'campaign_students'
      campaign.users_to_csv(:students, course: include_course, include_private:)
    when 'campaign_courses'
      builder.courses_to_csv
    when 'campaign_articles'
      builder.articles_to_csv
    when 'campaign_wikidata'
      builder.wikidata_to_csv
    end
  end

  def stream_campaign_zip(campaign_id, output_path, include_private: false)
    campaign = Campaign.find(campaign_id)
    builder = CampaignCsvBuilder.new(campaign, include_private:)
    csv_entries = campaign_zip_entries(campaign, builder, include_private:)

    Zip::OutputStream.open(output_path) do |zip|
      csv_entries.each do |entry_name, store_name, generator|
        zip.put_next_entry(entry_name)
        zip.write(fetch_or_build_csv(store_name, generator))
      end
    end
  end

  # The constituent files are the same ones the single-report endpoints cache,
  # so the variant with private courses must read and write the variant names.
  def campaign_zip_entries(campaign, builder, include_private: false)
    name = ->(type, course: false) { campaign_csv_name(campaign, type, course:, include_private:) }
    [
      ['students.csv', name.call('campaign_students'),
       -> { campaign.users_to_csv(:students, include_private:) }],
      ['students-by-course.csv', name.call('campaign_students', course: true),
       -> { campaign.users_to_csv(:students, course: true, include_private:) }],
      ['instructors-by-course.csv', name.call('campaign_instructors', course: true),
       -> { campaign.users_to_csv(:instructors, course: true, include_private:) }],
      ['courses.csv', name.call('campaign_courses'), -> { builder.courses_to_csv }],
      ['pages-edited.csv', name.call('campaign_articles'), -> { builder.articles_to_csv }]
    ]
  end

  def campaign_csv_name(campaign, type, course: false, include_private: false)
    self.class.campaign_csv_name(campaign, type, course:, include_private:)
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

  def report_data(type, id, include_course, filters, include_private: false)
    if type == 'all_courses_and_instructors'
      all_courses_and_instructors_csv
    elsif type == 'system_csv'
      to_system_csv(filters)
    elsif type == 'system_daily_stats_csv'
      to_system_daily_stats_csv(filters)
    elsif course_report?(type)
      to_course_csv(type, id)
    else
      to_campaign_csv(type, id, include_course, include_private:)
    end
  end

  def write_csv(filename, data)
    ReportCsvStore.write(filename, data)
  end

  def course_report?(type)
    type.start_with?('course')
  end
end
