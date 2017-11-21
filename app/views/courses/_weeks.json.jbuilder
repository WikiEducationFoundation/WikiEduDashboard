# frozen_string_literal: true

course_meetings_manager = CourseMeetingsManager.new(course)

json.weeks course.weeks.eager_load(blocks: [:gradeable]) do |week|
  # 0 index the array and offset according to blackout weeks prior
  week_array_index = week.order - 1 + course_meetings_manager.blackout_weeks_prior_to(week)
  if course.timeline_start
    start_date = course.timeline_start.beginning_of_week(:sunday) + (7 * week_array_index).days
  end
  json.call(week, :id, :order)
  json.start_date_raw start_date.present? ? start_date : nil
  json.end_date_raw start_date.present? ? start_date.end_of_week(:sunday) : nil
  json.start_date start_date.present? ? start_date.strftime('%m/%d') : nil
  json.end_date start_date.present? ? start_date.end_of_week(:sunday).strftime('%m/%d') : nil
  json.blocks week.blocks do |block|
    json.call(block, :id, :kind, :content, :week_id,
              :gradeable_id, :title, :order, :due_date,
              :training_module_ids)
    unless block.gradeable.nil?
      json.gradeable block.gradeable, :id, :points,
                     :gradeable_item_type, :gradeable_item_id
    end
    if block.training_modules.any?
      json.training_modules block.training_modules do |tm|
        # The available training modules may change over time, especially on
        # Programs & Events Dashboard where wiki trainings are enabled.
        # For modules that aren't found, simply skip sending info.
        next unless tm
        progress_manager = TrainingProgressManager.new(current_user, tm)
        due_date_manager = TrainingModuleDueDateManager.new(
          course: course,
          training_module: tm,
          user: current_user,
          course_meetings_manager: course_meetings_manager
        )
        json.call(tm, :slug, :id, :name)
        json.module_progress progress_manager.module_progress
        json.due_date due_date_manager.computed_due_date.strftime('%Y/%m/%d')
        json.overdue due_date_manager.overdue?
        json.deadline_status due_date_manager.deadline_status
      end
    end
  end
end
