# frozen_string_literal: true

json.current_term Campaign.default_campaign.slug
json.total_alerts @alerts.count
json.by_page_type @count_by_page_type
json.total_followups @followups.count
json.students_with_multiple_alerts @student_count_with_multiple_alerts
json.pages_with_multiple_alerts @page_count_with_multiple_alerts

json.recent_alerts_followup do
  json.partial! 'ai_edit_alerts_stats/ai_edit_alerts',
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
