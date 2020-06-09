# frozen_string_literal: true

class ErrorRecord
  attr_reader :error, :sentry_extra, :level
  attr_writer :level

  def initialize(error, sentry_extra, update_course_stats)
    @error = error
    @sentry_extra = sentry_extra
    @update_course_stats = update_course_stats
    @level = nil
  end

  def course
    @update_course_stats.course if @update_course_stats.present?
  end

  def course_present?
    course.present?
  end

  def course_slug
    course.slug if course_present?
  end

  def sentry_tag_uuid
    @update_course_stats.sentry_tag_uuid if course_present?
  end
end
