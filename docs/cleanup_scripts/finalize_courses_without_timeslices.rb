# frozen_string_literal: true
# This script flags as finalized the courses that ended more than 6 months ago
# and have no timeslice records (historical courses never updated through the
# timeslice system), so the timeslice purge jobs never pick them up.

timeslice_models = [CourseWikiTimeslice, CourseUserWikiTimeslice,
                    ArticleCourseTimeslice, ArticleCourseUserWikiTimeslice]

# Courses with a pending full update are skipped, since it could still create
# timeslices for them.
courses = Course.where('end < ?', 6.months.ago).where(needs_update: [false, nil])

finalized_count = 0
courses.find_each do |course|
  next if course.flags[:finalized].present?
  next if timeslice_models.any? { |model| model.exists?(course_id: course.id) }

  # update_columns skips validations and callbacks, so old courses that no
  # longer pass validation are still flagged.
  # rubocop:disable Rails/SkipsModelValidations
  course.update_columns(flags: course.flags.merge(finalized: true))
  # rubocop:enable Rails/SkipsModelValidations
  finalized_count += 1
end
puts "Flagged #{finalized_count} courses as finalized"
