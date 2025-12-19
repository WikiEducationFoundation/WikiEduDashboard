# frozen_string_literal: true

# Generates alerts about courses with recent spikes in AiEditAlerts
class CourseAiAlertManager
  def initialize(courses)
    @courses = courses
  end

  ALERT_COUNT_THRESHOLD = 3
  def create_alerts
    alert_tally_by_course = recent_priority_alerts.map(&:course_id).tally
    @courses.each do |course|
      alert_count = alert_tally_by_course[course.id] || 0
      next unless alert_count >= ALERT_COUNT_THRESHOLD
      next if recent_unresolved_alert_exists?(course)
      create_alert_for_course(course, alert_count)
    end
  end

  private

  RECENT_DAYS = 14
  def recent_ai_edit_alerts
    @recent_edit_alerts ||= AiEditAlert.where('created_at > ?', RECENT_DAYS.days.ago)
  end

  # These are the AiEditAlert#page_type values that represent
  # live article content or content likely to end up mainspace.
  PRIORITY_PAGE_TYPES = [:mainspace, :draft, :sandbox, :unknown].freeze
  def recent_priority_alerts
    @recent_priority_alerts ||= recent_ai_edit_alerts.filter do |alert|
      PRIORITY_PAGE_TYPES.include? alert.page_type
    end
  end

  def create_alert_for_course(course, count)
    course_alerts = recent_ai_edit_alerts.filter { |a| a.course_id == course.id }
    recent_alert_tally_by_type = course_alerts.map(&:page_type).tally
    course_priority_alerts = recent_priority_alerts.filter { |a| a.course_id == course.id }
    recent_priority_alert_ids = course_priority_alerts.map(&:id)
    details = {
      high_priority_alert_count: count,
      recent_priority_alert_ids:,
      recent_alert_tally_by_type:
    }

    alert = AiSpikeAlert.create(course:, details:)
    alert.send_email
  end

  # Using the same recency window as for the AiEditAlerts themselves, so a second
  # alert for the same course would cover a non-overlapping window.
  def recent_unresolved_alert_exists?(course)
    AiSpikeAlert.where(course_id: course.id, resolved: false)
                .exists?(['created_at > ?', RECENT_DAYS.days.ago])
  end
end
