# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/course_purge_checks"

#= Flags old courses as purgeable so a later job can delete their timeslices and
#  keep the timeslice tables from growing without bound. A course is purgeable
#  once it passes CoursePurgeChecks.
class MarkPurgeableCourses
  attr_reader :marked_count

  def initialize
    @marked_count = 0
    mark_purgeable_courses
  end

  private

  def mark_purgeable_courses
    Course.where('end < ?', CoursePurgeChecks::PURGEABLE_AFTER.ago).find_each do |course|
      mark_if_purgeable(course)
    end
  end

  def mark_if_purgeable(course)
    return if course.purgeable? || course.finalized?
    return unless CoursePurgeChecks.new(course).passed?

    if course.add_flag(key: :purgeable)
      @marked_count += 1
    else
      log_flag_failure(course)
    end
  end

  # add_flag doesn't save when the course fails validation or a before_save
  # callback aborts. The course is checked again on the next run.
  def log_flag_failure(course)
    Rails.logger.warn "MarkPurgeableCourses: failed to flag #{course.slug} as " \
                      "purgeable: #{course.errors.full_messages.join(', ')}"
  end
end
