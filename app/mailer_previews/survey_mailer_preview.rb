# frozen_string_literal: true

# Preview all emails at http://localhost:3000/rails/mailers/survey_mailer

require_relative 'mailer_preview_helpers'

class SurveyMailerPreview < ActionMailer::Preview
  include MailerPreviewHelpers

  DESCRIPTION = 'Survey invitations and follow-up reminders sent to instructors and students.'
  METHOD_DESCRIPTIONS = {
    instructor_survey_notification: 'Invitation to an instructor to complete a course survey',
    instructor_survey_follow_up: 'Reminder to an instructor who has not yet completed the survey',
    student_learning_preassessment_notification:
      'Invitation to a student to complete a pre-assessment survey',
    student_learning_preassessment_follow_up:
      'Reminder to a student who has not completed the pre-assessment',
    custom_notification: 'Initial invitation using a custom email subject, headline, and body',
    custom_follow_up: 'Follow-up reminder using a custom email subject, headline, and body'
  }.freeze

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
    survey = OpenStruct.new(id: 10001, name: 'Survey one')
    survey_assignment = OpenStruct.new(survey:,
                                       custom_email_subject: 'Survey: the best wikipedia articles')
    survey_assignment.custom_email_headline = 'Pick your 3 favorite articles'
    survey_assignment.custom_email_body = 'You will have to chose three articles.'
    survey_assignment.custom_email_signature = 'The survey creator'
    OpenStruct.new(survey_assignment:,
                   course: example_course,
                   survey:, user:
                      User.new(email: 'sage@example.com', username: 'Ragesoss'))
  end
end
