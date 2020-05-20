# frozen_string_literal: true

module CourseUpdateErrorHandling
  def save_course_error_record(course, error, url: nil, miscellaneous: nil)
    return unless course.present?
    CourseErrorRecord.create(course: course,
                             type_of_error: error.class,
                             api_call_url: url,
                             miscellaneous: miscellaneous)
  end
end
