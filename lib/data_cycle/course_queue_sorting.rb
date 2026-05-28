# frozen_string_literal: true

module CourseQueueSorting
  # Number of consecutive unfinished updates that triggers escalation to long_update queue
  UNFINISHED_UPDATES_LONG_QUEUE_THRESHOLD = 2

  def queue_for(course)
    update_longest_update_time(course)
    return 'very_long_update' if course.very_long_update?
    return 'long_update' if too_many_consecutive_unfinished_updates?(course)

    case longest_recent_update_time(course)
    when nil
      initial_queue(course)
    when 0..30 # up to 30 seconds
      'short_update'
    when 31..600 # up to 10 minutes
      'medium_update'
    when (601..) # more than 10 minutes
      'long_update'
    end
  end

  def too_many_consecutive_unfinished_updates?(course)
    consecutive_unfinished_updates(course) >= UNFINISHED_UPDATES_LONG_QUEUE_THRESHOLD
  end

  # Returns the number of consecutive update failures since the last success.
  # Old unfinished entries that predate the last successful end_time are excluded,
  # since they're not evidence of a current problem.
  def consecutive_unfinished_updates(course)
    unfinished_logs = course.flags['unfinished_update_logs']
    return 0 unless unfinished_logs.present?

    finished_logs = course.flags['update_logs']
    latest_end = finished_logs&.values&.filter_map { |log| log['end_time'].to_f }&.max || 0
    unfinished_logs.values.count { |log| log['start_time'].to_f > latest_end }
  end

  def longest_recent_update_time(course)
    logs = course.flags['update_logs']
    return unless logs.present?
    update_times = logs.keys.map do |update_number|
      logs[update_number]['end_time'].to_f - logs[update_number]['start_time'].to_f
    end
    update_times.max.to_i
  end

  def longest_update_time(course)
    course.flags[:longest_update]
  end

  def initial_queue(course)
    course_length = course.end - course.start
    not_ended = Time.zone.now < course.end
    if course_length < 3.days && not_ended
      'short_update'
    else
      'medium_update'
    end
  end

  def update_longest_update_time(course)
    return unless longest_recent_update_time(course).to_i >= longest_update_time(course).to_i

    course.flags[:longest_update] = longest_recent_update_time(course)
    course.save
  end
end
