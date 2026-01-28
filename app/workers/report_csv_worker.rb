# frozen_string_literal: true
require_dependency "#{Rails.root}/lib/analytics/campaign_csv_builder"
require_dependency "#{Rails.root}/lib/analytics/course_csv_builder"
require_dependency "#{Rails.root}/lib/analytics/course_uploads_csv_builder"
require_dependency "#{Rails.root}/lib/analytics/course_students_csv_builder"
require_dependency "#{Rails.root}/lib/analytics/course_articles_csv_builder"
require_dependency "#{Rails.root}/lib/analytics/course_wikidata_csv_builder"
require_dependency "#{Rails.root}/app/controllers/reports_controller"
require_dependency "#{Rails.root}/app/workers/csv_cleanup_worker"

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
        all_courses_and_instructors_to_csv
      elsif course_report?(type)
        to_course_csv(type, id)
      else
        to_campaign_csv(type, id, include_course)
      end

    raise "CSV data was nil for type=#{type}" if data.nil?

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

  private

  def write_csv(filename, data)
    FileUtils.mkdir_p "public#{ReportsController::CSV_PATH}"
    File.write "public#{ReportsController::CSV_PATH}/#{filename}", data
  end

  def course_report?(type)
    type.start_with?('course')
  end

  def all_courses_and_instructors_to_csv
    CSV.generate do |csv|
      write_all_courses_headers(csv)
      each_public_course do |course|
        write_course_rows(csv, course)
      end
    end
  end

  def write_all_courses_headers(csv)
    csv << all_courses_headers
  end

  def all_courses_headers
    [
      'Course ID',
      'Created At',
      'Slug',
      'Title',
      'Institution',
      'Start',
      'End',
      'Facilitator',
      'Wiki'
    ]
  end

  def public_courses_scope
    Course
      .where(private: false)
      .preload(:instructors, :wikis)
      .order(:id)
  end

  def each_public_course
    public_courses_scope.find_each(batch_size: 1000) do |course|
      yield course
    end
  end

  def write_course_rows(csv, course)
    base_row = base_course_row(course)
    write_facilitator_rows(csv, base_row, course)
    write_wiki_rows(csv, base_row, course)
  end

  def base_course_row(course)
    [
      course.id,
      course.created_at&.utc&.iso8601,
      course.slug,
      course.title,
      course.school,
      course.start.to_s,
      course.end.to_s
    ]
  end

  def write_facilitator_rows(csv, base_row, course)
    course.instructors.each do |facilitator|
      csv << (base_row + [facilitator.username, nil])
    end
  end

  def write_wiki_rows(csv, base_row, course)
    course.wikis.each do |wiki|
      csv << (base_row + [nil, wiki.domain])
    end
  end
end
