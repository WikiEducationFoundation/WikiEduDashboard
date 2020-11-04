# frozen_string_literal: true

module CourseQueueSorting
  def queue_for(course)
    case average_update_time(course)
    when nil
      initial_queue(course)
    when 0..30 # up to 30 seconds
      'short_update'
    when 31..600 # up to 10 minutes
      'medium_update'
    when (601..Float::INFINITY) # more than 10 minutes
      'long_update'
    end
  end

  def average_update_time(course)
    logs = course.flags['update_logs']
    return unless logs.present?
    total_time = logs.keys.sum do |update_number|
      logs[update_number]['end_time'].to_f - logs[update_number]['start_time'].to_f
    end
    (total_time / logs.keys.count).to_i
  end

  def initial_queue(course)
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
