# frozen_string_literal: true

require 'rails_helper'

describe SurveyNotificationsController, type: :request do
  describe '#update' do
    let(:owner) { create(:user) }
    let(:other_user) { create(:user, username: 'OtherUser') }
    let(:course) { create(:course) }
    let(:courses_user) { create(:courses_user, course_id: course.id, user_id: owner.id) }
    let(:survey_notification) do
      create(:survey_notification, courses_users_id: courses_user.id, course_id: course.id)
    end
    let(:params) do
      { survey_notification: { id: survey_notification.id, dismissed: true, completed: false } }
    end

    it 'renders a success message if update succeeds' do
      login_as owner
      put '/survey_notification', params: params
      expect(response.body).to eq({ success: true }.to_json)
      expect(survey_notification.reload.dismissed).to eq(true)
    end

    it 'renders an error message if update fails' do
      login_as owner
      expect_any_instance_of(SurveyNotification).to receive(:update)
      put '/survey_notification', params: params
      expect(response.body).to eq({ error: {} }.to_json)
    end

    it 'refuses a logged-out visitor' do
      put '/survey_notification', params: params
      expect(response.status).to eq(401)
      expect(survey_notification.reload.dismissed).to eq(false)
    end

    it 'refuses a user who does not own the notification' do
      login_as other_user
      put '/survey_notification', params: params
      expect(response.status).to eq(401)
      expect(survey_notification.reload.dismissed).to eq(false)
    end
  end
end
