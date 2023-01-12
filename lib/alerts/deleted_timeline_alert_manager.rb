# frozen_string_literal: true

class DeletedTimelineAlertManager
  def initialize(course)
    @course = course
  end

  def create_alerts
    return unless @course.approved?
    # it will not create an alert if course has more than 1 week
    return if @course.weeks.count > 1
    alert = Alert.create(type: 'DeletedUploadsAlert', course_id: @course.id, message: "It appears you have removed either the timeline, week or block from your course.")
    alert.email_content_expert
  end
end