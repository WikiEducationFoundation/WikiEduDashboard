# frozen_string_literal: true

class DeletedUploadsAlertManager
  def initialize(courses)
    @courses = courses
  end

  def create_alerts
    @courses.each do |course|
      next unless too_many_deleted_uploads?(course)
      next if Alert.exists?(course_id: course.id, type: 'DeletedUploadsAlert')
      alert = Alert.create(type: 'DeletedUploadsAlert', course_id: course.id)
      alert.email_content_expert
    end
  end

  private

  TOO_MANY_DELETED_UPLOADS = 5
  def too_many_deleted_uploads?(course)
    course.uploads.where(deleted: true).count >= TOO_MANY_DELETED_UPLOADS
  end
end
