# frozen_string_literal: true

require 'rails_helper'

describe SurveyNotificationsController do
  describe '#update' do
    let(:survey_notification) { create(:survey_notification) }
    let(:params) do
      { survey_notification: { id: survey_notification.id, dismissed: true, completed: false } }
    end

    it 'renders a success message if update succeeds' do
      post :update, params: params
      expect(response.body).to eq({ success: true }.to_json)
      expect(survey_notification.reload.dismissed).to eq(true)
    end

    it 'renders an error message if update fails' do
      expect_any_instance_of(SurveyNotification).to receive(:update)
      post :update, params: params
      expect(response.body).to eq({ error: {} }.to_json)
    end
  end
end
