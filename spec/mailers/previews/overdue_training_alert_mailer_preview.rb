# frozen_string_literal: true

class OverdueTrainingAlertMailerPreview < ActionMailer::Preview
  def message_to_student
    OverdueTrainingAlertMailer.email(example_alert)
  end

  private

  def example_alert_details
    { 'wikipedia-essentials' =>
      { due_date: 2.weeks.ago, status: 'complete', progress: 'Completed' },
     'sandboxes-talk-watchlists' =>
      { due_date: 1.week.ago, status: 'complete', progress: 'Completed' },
     'moving-to-mainspace' =>
      { due_date: 1.day.ago, status: 'overdue', progress: nil },
     'moving-to-mainspace-group' =>
      { due_date: 1.day.ago, status: 'overdue', progress: nil } }
  end

  def example_alert
    OverdueTrainingAlert.new(user: example_profile.user,
                             course: Course.first,
                             details: example_alert_details)
  end

  def example_user
    User.new(email: 'sage@example.com', username: 'Ragesoss')
  end

  def example_profile
    UserProfile.new(user: example_user, email_preferences: { token: 'abcde' })
  end
end
