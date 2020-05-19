# frozen_string_literal: true

module CourseQueueSorting
  def queue_for(course)
    course_length = course.end - course.start
    not_ended = Time.zone.now < course.end
    if course_length < 3.days && not_ended
      'short_update'
    elsif course_length < 6.months
      'medium_update'
    else
      'long_update'
    end
  end
end
