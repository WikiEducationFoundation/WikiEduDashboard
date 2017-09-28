# frozen_string_literal: true

require 'ostruct'

# Sends a test to a user to show what the survey emails will look like.
class SurveyTestEmailManager
  def self.send_test_email(survey_assignment, current_user)
    new(survey_assignment, current_user).send_email
  end

  def initialize(survey_assignment, current_user)
    @survey_assignment = survey_assignment
    @user = current_user
    @mock_notification = mock_survey_notification
  end

  # Create an object that has all the properties SurveyMailer expects, without
  # creating a real SurveyNotification object. This lets the email tester bypass
  # the assumption of a real CoursesUsers record for each SurveyNotification.
  def mock_survey_notification
    OpenStruct.new(
      user: @user,
      survey: @survey_assignment.survey,
      survey_assignment: @survey_assignment,
      course: Course.last
    )
  end

  def send_email
    SurveyMailer.send_notification(@mock_notification)
  end
end
