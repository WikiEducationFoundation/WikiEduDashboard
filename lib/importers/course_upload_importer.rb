# frozen_string_literal: true

require_dependency Rails.root.join('lib/importers/upload_importer')

#= Imports uploads by students during a course
class CourseUploadImporter
  def initialize(course, update_service: nil)
    @course = course
    @update_service = update_service
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
    @course.students.in_groups_of(40, false) do |user_batch|
      UploadImporter.import_uploads uploads_data(user_batch)
    end
  end

  def import_thumbnail_urls
    UploadImporter.import_urls_in_batches(@course.uploads.where(thumburl: nil, deleted: false),
                                          update_service: @update_service)
  end

  def update_usage
    UploadImporter.update_usage_count(@course.uploads, update_service: @update_service)
  end

  def uploads_data(users)
    Commons.get_uploads(users, start_date: @start, end_date: @end, update_service: @update_service)
  end
end
