# frozen_string_literal: true
# Preview all emails at http://localhost:3000/rails/mailers/instructor_notification

class InstructorNotificationPreview < ActionMailer::Preview
  def message_to_instructors
    InstructorNotificationMailer.email(example_alert, true)
  end

  private

  def example_alert
    InstructorNotificationAlert.new(type: 'InstructorNotificationAlert',
                                    course: Course.nonprivate.last,
                                    message: 'Hello from Admin, This
                                    is a test notification!',
                                    user_id: 1,
                                    subject: 'Test Subject')
  end
end
