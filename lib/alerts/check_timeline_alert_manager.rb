# frozen_string_literal: true

class CheckTimelineAlertManager
  def initialize(course)
    @course = course
    create_alerts
  end

  def create_alerts
    return unless @course.approved?
    # if course doesn't have any training module, it will not create an alert
    return if @course.training_module_ids.any?
    return if alert_already_exists?
    alert = Alert.create(type: 'CheckTimelineAlert',
                         course: @course,
                         message: CheckTimelineAlert.default_message)
    alert.email_content_expert
  end

  def alert_already_exists?
    CheckTimelineAlert.exists?(course: @course, resolved: false)
  end
end
