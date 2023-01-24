# frozen_string_literal: true

class CheckTimelineManager
  def initialize(course)
    @course = course
    msg = CheckTimeline.default_message
    create_alerts(msg)
  end

  def create_alerts(msg)
    return unless @course.approved?
    # if course doesn't have any training module, it will not create an alert
    return if @course.training_module_ids.any?
    puts msg
    # alert = Alert.create(type: 'CheckTimeline', course_id: @course.id, message: msg)
    alert = Alert.create(type: 'CheckTimeline',
                         course_id: @course.id,
                         message: msg)
    alert.email_content_expert
  end
end
