# frozen_string_literal: true

module CourseUpdateErrorHandling
  def save_course_error_record(course, error, sentry_tag_uuid, optional_params)
    CourseErrorRecord.create(course: course,
                             type_of_error: error.class,
                             sentry_tag_uuid: sentry_tag_uuid,
                             api_call_url: optional_params[:url],
                             miscellaneous: optional_params[:miscellaneous])
  end
end
