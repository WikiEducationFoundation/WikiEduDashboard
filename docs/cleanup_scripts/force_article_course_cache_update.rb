# frozen_string_literal: true
# Touch article course timeslices to force an article course cache for every article
# course in the next course update.
# We had to do this after the hot fix for article views.

# This is the query to get the courses to be fixed
# SELECT id
# FROM courses
# WHERE flags like '%reprocessed%' AND updated_at <= '2025-02-27 22:03:12';
# Note that flags like '%reprocessed%' is an easy way to get courses that already got an update
# in the timeslice system

second_deployment_timestamp = Time.zone.parse('2025-02-27 22:03:12')
courses_to_fix = Course.where('flags LIKE ? AND updated_at <= ?', '%reprocessed%',
                              second_deployment_timestamp)

courses_to_fix.each do |course|
  # rubocop:disable Rails/SkipsModelValidations
  course.article_course_timeslices.touch_all(:updated_at)
  # rubocop:enable Rails/SkipsModelValidations
end
