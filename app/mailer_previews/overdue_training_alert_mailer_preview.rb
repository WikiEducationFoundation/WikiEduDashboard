# frozen_string_literal: true

require_relative 'mailer_preview_helpers'

class OverdueTrainingAlertMailerPreview < ActionMailer::Preview
  include MailerPreviewHelpers

  DESCRIPTION = 'Sent to students who have training modules past due on their course timeline.'
  METHOD_DESCRIPTIONS = {
    message_to_student: 'Lists overdue modules and links the student to complete them'
  }.freeze

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
                             course: example_course,
                             details: example_alert_details)
  end

  def example_user
    User.new(email: 'sage@example.com', username: 'Ragesoss')
  end

  def example_profile
    UserProfile.new(user: example_user, email_preferences: { token: 'abcde' })
  end
end
