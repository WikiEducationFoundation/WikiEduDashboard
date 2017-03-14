# frozen_string_literal: true

#= Preview all emails at http://localhost:3000/rails/mailers/survey_mailer
class AlertPreview < ActionMailer::Preview
  def articles_for_deletion_alert
    AlertMailer.alert(Alert.where(type: 'ArticlesForDeletionAlert').last, example_user)
  end

  def productive_course_alert
    AlertMailer.alert(Alert.where(type: 'ProductiveCourseAlert').last, example_user)
  end

  def continued_course_activity_alert
    AlertMailer.alert(Alert.where(type: 'ContinuedCourseActivityAlert').last, example_user)
  end

  def need_help_alert
    AlertMailer.alert(Alert.where(type: 'NeedHelpAlert').last, example_user)
  end

  def generic_alert
    AlertMailer.alert(Alert.last, example_user)
  end

  private

  def example_user
    User.new(email: 'sage@example.com', username: 'Ragesoss')
  end
end
