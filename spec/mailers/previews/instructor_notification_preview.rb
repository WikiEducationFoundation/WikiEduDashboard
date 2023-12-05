# Preview all emails at http://localhost:3000/rails/mailers/instructor_notification
class InstructorNotificationPreview < ActionMailer::Preview
  def message_to_instructors
    InstructorNotificationMailer.email(example_alert)
  end

  private

  def example_alert
    Alert.new(type: 'InstructorNotificationAlert', course: Course.nonprivate.last, message:"Hello from Admin, This is a test notification!")
  end
end
