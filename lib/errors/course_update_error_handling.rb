# frozen_string_literal: true

module CourseUpdateErrorHandling
  def save_course_error_record(course, type_of_error, url)
    return unless course.present?
    CourseErrorRecord.create(course: course, type_of_error: type_of_error, api_call_url: url)
  end
end
