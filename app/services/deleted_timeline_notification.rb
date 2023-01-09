class DeletedTimelineNotification < Alert
  def initialize(course)
    @course = course
    create_alerts
  end

  def create_alerts
    alert = Alert.create(type: 'DeletedTimelineAlert', course: @course, message: 'It appears you have removed either the timeline, week or block from your course.')
    alert.email_course_admins
  end
end