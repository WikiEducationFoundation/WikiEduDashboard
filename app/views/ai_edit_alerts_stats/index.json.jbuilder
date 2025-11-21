# frozen_string_literal: true

json.campaign_name @campaign_name
json.total_alerts @alerts.count
json.by_page_type @count_by_page_type
json.total_followups @followups.count
json.students_with_multiple_alerts @student_count_with_multiple_alerts
json.pages_with_multiple_alerts @page_count_with_multiple_alerts
json.historical_alerts @historical_alerts

json.recent_alerts_followup do
  json.partial! 'ai_edit_alerts_stats/recent_followup_ai_edit_alerts',
                alerts: @alerts_with_recent_followup
end

json.recent_alerts_for_students_with_multiple_alerts do
  json.partial! 'ai_edit_alerts_stats/ai_edit_alerts',
                alerts: @recent_alerts_for_students_with_multiple_alerts
end

json.recent_alerts_for_mainspace do
  json.partial! 'ai_edit_alerts_stats/ai_edit_alerts',
                alerts: @recent_alerts_for_mainspace
end

json.courses_with_ai_edit_alerts do
  json.partial! 'ai_edit_alerts_stats/courses_with_ai_edit_alerts',
                courses: @courses
end
