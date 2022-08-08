# frozen_string_literal: true

json.weeks course.weeks.eager_load(:blocks) do |week|
  # 0 index the array and offset according to blackout weeks prior
  week_array_index = week.order - 1 + course.meetings_manager.blackout_weeks_prior_to(week)
  if course.timeline_start
    start_date = course.timeline_start.beginning_of_week(:sunday) + (7 * week_array_index).days
  end
  json.call(week, :id, :order)
  json.start_date_raw start_date.presence
  json.end_date_raw start_date.present? ? start_date.end_of_week(:sunday) : nil
  json.start_date start_date.present? ? start_date.strftime('%m/%d') : nil
  json.end_date start_date.present? ? start_date.end_of_week(:sunday).strftime('%m/%d') : nil
  json.title week.title
  json.blocks week.blocks do |block|
    json.partial! 'courses/block', block:, course:
  end
end
