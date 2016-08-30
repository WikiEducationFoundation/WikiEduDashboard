# frozen_string_literal: true

# Alert for a course that has too many deleted uploads
class DeletedUploadsAlert < Alert
  def main_subject
    course.slug
  end

  def url
    course_url
  end
end
