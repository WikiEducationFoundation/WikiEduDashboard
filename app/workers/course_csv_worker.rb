# frozen_string_literal: true
require_dependency "#{Rails.root}/app/workers/csv_cleanup_worker"

class CourseCsvWorker
  include Sidekiq::Worker
  sidekiq_options lock: :until_executed

  def self.generate_csv(course:, filename:, type:)
    perform_async(course.id, filename, type)
  end

  def perform(course_id, filename, type)
    course = Course.find(course_id)
    data = to_csv(type, course)

    write_csv(filename, data)
    CsvCleanupWorker.perform_at(1.week.from_now, filename)
  end

  def to_csv(type, course)
    case type
    when 'overview'
      CourseCsvBuilder.new(course, per_wiki: true).generate_csv
    when 'editors'
      CourseStudentsCsvBuilder.new(course).generate_csv
    when 'uploads'
      CourseUploadsCsvBuilder.new(course).generate_csv
    when 'articles'
      CourseArticlesCsvBuilder.new(course).generate_csv
    when 'wikidata'
      CourseWikidataCsvBuilder.new(course).generate_csv
    end
  end

  private

  def write_csv(filename, data)
    FileUtils.mkdir_p "public#{AnalyticsController::CSV_PATH}"
    File.write "public#{AnalyticsController::CSV_PATH}/#{filename}", data
  end
end
