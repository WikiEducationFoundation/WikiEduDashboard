# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/importers/upload_importer"

#= Imports uploads by students during a course
class CourseUploadImporter
  def initialize(course, update_service: nil, reporter: nil)
    @course = course
    @update_service = update_service
    @reporter = reporter || UpdateProgressReporter.new
    @start = course.start
    @end = course.end + Course::UPDATE_LENGTH
  end

  def run
    import_uploads
    import_thumbnail_urls
    update_usage
  end

  private

  def import_uploads
    student_batches = @course.students.in_groups_of(40, false).to_a
    @reporter.phase('uploads_fetch', total: student_batches.size)
    student_batches.each_with_index do |user_batch, i|
      UploadImporter.import_uploads uploads_data(user_batch)
      @reporter.progress(at: i + 1, message: "user batch #{i + 1}/#{student_batches.size}")
    end
  end

  def import_thumbnail_urls
    @reporter.phase('uploads_thumbnails')
    UploadImporter.import_urls_in_batches(@course.uploads.where(thumburl: nil, deleted: false),
                                          update_service: @update_service)
  end

  def update_usage
    @reporter.phase('uploads_usage')
    UploadImporter.update_usage_count(@course.uploads, update_service: @update_service)
  end

  def uploads_data(users)
    Commons.get_uploads(users, start_date: @start, end_date: @end, update_service: @update_service)
  end
end
