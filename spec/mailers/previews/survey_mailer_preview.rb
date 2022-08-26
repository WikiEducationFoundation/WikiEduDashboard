# frozen_string_literal: true

# Preview all emails at http://localhost:3000/rails/mailers/survey_mailer
class SurveyMailerPreview < ActionMailer::Preview
  def instructor_survey_notification
    SurveyMailer.instructor_survey_notification(example_notification)
  end

  def instructor_survey_follow_up
    SurveyMailer.instructor_survey_follow_up(example_notification)
  end

  def student_learning_preassessment_notification
    SurveyMailer.student_learning_preassessment_notification(example_notification)
  end

  def student_learning_preassessment_follow_up
    SurveyMailer.student_learning_preassessment_follow_up(example_notification)
  end

  def custom_notification
    SurveyMailer.custom_notification(example_notification)
  end

  def custom_follow_up
    SurveyMailer.custom_follow_up(example_notification)
  end

  private

  def example_notification
    notification = SurveyNotification.new(
      survey_assignment: SurveyAssignment.last,
      course: Course.nonprivate.last
    )
    def notification.user
      User.new(email: 'sage@example.com', username: 'Ragesoss')
    end
    notification
  end
end
