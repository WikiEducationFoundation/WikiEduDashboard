# frozen_string_literal: true

# Preview all emails at http://localhost:3000/rails/mailers/instructor_notification

class InstructorNotificationPreview < ActionMailer::Preview
  DESCRIPTION = 'Admin-authored notification emails sent directly to all instructors in a course.'
  METHOD_DESCRIPTIONS = {
    message_to_instructors: 'Custom notification from an admin to all course instructors'
  }.freeze

  def message_to_instructors
    InstructorNotificationMailer.email(example_alert, true)
  end

  private

  def example_alert
    InstructorNotificationAlert.new(type: 'InstructorNotificationAlert',
                                    course: example_course,
                                    message: 'Hello from Admin, This
                                    is a test notification!',
                                    user_id: 1,
                                    subject: 'Test Subject')
  end

  def example_course
    Course.new(
      title: 'Advanced Topics in Global Health',
      slug: 'Global_Health/Advanced_Topics_(Spring_2025)',
      school: 'University of Maryland',
      expected_students: 24,
      user_count: 22,
      start: 3.months.ago,
      end: 1.month.from_now,
      revision_count: 450
    )
  end
end
