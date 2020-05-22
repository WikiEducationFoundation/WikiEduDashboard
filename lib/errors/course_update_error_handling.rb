# frozen_string_literal: true

module CourseUpdateErrorHandling
  def save_course_error_record(course, error, sentry_tag_uuid, url: nil, miscellaneous: nil)
    CourseErrorRecord.create(course: course,
                             type_of_error: error.class,
                             api_call_url: url,
                             sentry_tag_uuid: sentry_tag_uuid,
                             miscellaneous: miscellaneous)
  end
end
