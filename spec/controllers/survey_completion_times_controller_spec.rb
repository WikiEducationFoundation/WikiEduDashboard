# frozen_string_literal: true

require 'rails_helper'

describe SurveyCompletionTimesController, type: :request do
  let(:user) { create(:user) }
  let(:survey) { create(:survey) }

  before do
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
  end

  describe '#start' do
    it 'creates a completion time record and returns tracking_id' do
      post '/survey/start', params: { survey_id: survey.id }
      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      expect(json['tracking_id']).to be_present

      record = SurveyCompletionTime.find(json['tracking_id'])
      expect(record.survey_id).to eq(survey.id)
      expect(record.user_id).to eq(user.id)
      expect(record.started_at).to be_present
      expect(record.completed_at).to be_nil
    end

    it 'accepts an optional survey_notification_id' do
      post '/survey/start', params: { survey_id: survey.id, survey_notification_id: 42 }
      json = JSON.parse(response.body)
      record = SurveyCompletionTime.find(json['tracking_id'])
      expect(record.survey_notification_id).to eq(42)
    end
  end

  describe '#complete' do
    let!(:completion_record) do
      create(:survey_completion_time,
              survey: survey,
              user: user,
              started_at: 5.minutes.ago)
    end

    it 'sets completed_at and returns computed duration' do
      put '/survey/complete', params: { tracking_id: completion_record.id }
      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      expect(json['duration_in_seconds']).to be_within(2).of(300)

      completion_record.reload
      expect(completion_record.completed_at).to be_present
      expect(completion_record.duration_in_seconds).to be_within(2).of(300)
    end
  end
end
