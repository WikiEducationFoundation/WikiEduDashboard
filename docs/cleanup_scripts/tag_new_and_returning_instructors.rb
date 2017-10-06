# frozen_string_literal: true

# This script retroactively tags all the courses with either
# 'first_time_instructor' or 'returning_instructor'.
Course.all.each do |course|
  tags = course.tags.pluck(:tag)
  next if tags.include?('returning_instructor')
  next if tags.include?('first_time_instructor')
  instructor = course.instructors.first
  next if instructor.nil?
  start_dates = instructor.courses.pluck(:start)
  tag_attrs = { course_id: course.id, key: 'cleanup_script_2016-03-23' }
  tag_attrs[:tag] = if course.start == start_dates.min
                      'first_time_instructor'
                    else
                      'returning_instructor'
                    end
  Tag.create(tag_attrs)
end
