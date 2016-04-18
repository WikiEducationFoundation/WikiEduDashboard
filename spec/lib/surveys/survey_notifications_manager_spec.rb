require 'rails_helper'
require "#{Rails.root}/lib/surveys/survey_notifications_manager"

describe SurveyNotificationsManager do
  describe '.create_notifications' do
    include_context 'survey_assignment'

    it 'creates SurveyNotifications for each courses_user ready for a survey' do
      described_class.create_notifications
      expect(SurveyNotification.all.length).to eq(2)
    end

    it 'only creates notifications with unique courses_user id and survey id combinations' do
      new_survey = create(:survey)
      survey_assignment = create(
        :survey_assignment,
        published: true,
        courses_user_role: 1,
        survey_id: new_survey.id,
        send_date_days: 3,
        send_before: true,
        send_date_relative_to: 'end'
      )
      survey_assignment.cohorts << @cohort1
      survey_assignment.save
      described_class.create_notifications
      expect(SurveyNotification.all.count).to eq(4)
    end
  end
end
