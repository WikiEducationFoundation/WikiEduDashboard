# frozen_string_literal: true

class ErrorRecord
  attr_reader :error, :sentry_extra, :course, :course_extra,
              :level, :sentry_tag_uuid
  attr_writer :level, :sentry_tag_uuid, :course_extra
  def initialize(error, sentry_extra, course, course_extra)
    @error = error
    @sentry_extra = sentry_extra
    @course = course
    @course_extra = course_extra
    @level = nil
    @sentry_tag_uuid = nil
  end

  def course_present?
    @course.present?
  end
end
