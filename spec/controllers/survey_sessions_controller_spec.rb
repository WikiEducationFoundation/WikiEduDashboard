# frozen_string_literal: true

require 'rails_helper'

describe SurveySessionsController, type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user, username: 'Other user') }
  let(:survey) { create(:survey) }

  before do
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
  end

  describe '#start' do
    it 'creates a session record and returns tracking_id' do
      post '/survey/start', params: { survey_id: survey.id }
      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      expect(json['tracking_id']).to be_present

      record = SurveySession.find(json['tracking_id'])
      expect(record.survey_id).to eq(survey.id)
      expect(record.user_id).to eq(user.id)
      expect(record.started_at).to be_present
      expect(record.completed_at).to be_nil
    end

    it 'accepts an optional survey_notification_id' do
      post '/survey/start', params: { survey_id: survey.id, survey_notification_id: 42 }
      json = JSON.parse(response.body)
      record = SurveySession.find(json['tracking_id'])
      expect(record.survey_notification_id).to eq(42)
    end
  end

  describe '#complete' do
    let!(:session_record) do
      create(:survey_session,
              survey: survey,
              user: user,
              started_at: 5.minutes.ago)
    end

    it 'sets completed_at and returns computed duration' do
      put '/survey/complete', params: { tracking_id: session_record.id }
      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      expect(json['duration_in_seconds']).to be_within(2).of(300)

      session_record.reload
      expect(session_record.completed_at).to be_present
      expect(session_record.duration_in_seconds).to be_within(2).of(300)
    end

    context 'when the session belongs to a different user' do
      let!(:other_session) do
        create(:survey_session,
                survey: survey,
                user: other_user,
                started_at: 5.minutes.ago)
      end

      it 'returns not_found and does not complete the session' do
        put '/survey/complete', params: { tracking_id: other_session.id }
        expect(response).to have_http_status(:not_found)

        other_session.reload
        expect(other_session.completed_at).to be_nil
      end
    end

    context 'when the session is already completed' do
      let(:original_completed_at) { 2.minutes.ago.change(usec: 0) }

      before do
        session_record.update!(completed_at: original_completed_at)
      end

      it 'does not overwrite the original completed_at' do
        put '/survey/complete', params: { tracking_id: session_record.id }
        expect(response).to have_http_status(:ok)

        session_record.reload
        expect(session_record.completed_at).to be_within(1.second).of(original_completed_at)
      end
    end
  end

  describe 'authentication' do
    before do
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(nil)
      allow_any_instance_of(ApplicationController).to receive(:user_signed_in?).and_return(false)
    end

    it 'rejects unauthenticated #start' do
      expect {
        post '/survey/start', params: { survey_id: survey.id }
      }.to raise_error(NotSignedInError)
    end

    it 'rejects unauthenticated #complete' do
      session_record = create(:survey_session, survey: survey, user: user, started_at: 5.minutes.ago)
      expect {
        put '/survey/complete', params: { tracking_id: session_record.id }
      }.to raise_error(NotSignedInError)
    end
  end
end
