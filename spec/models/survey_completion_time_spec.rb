# frozen_string_literal: true

require 'rails_helper'

describe SurveyCompletionTime do
  let(:user) { create(:user) }
  let(:survey) { create(:survey) }

  describe '#compute_duration!' do
    it 'computes duration when both started_at and completed_at are set' do
      record = create(:survey_completion_time,
                       survey: survey,
                       user: user,
                       started_at: 10.minutes.ago,
                       completed_at: Time.zone.now)
      record.compute_duration!
      expect(record.duration_in_seconds).to be_within(2).of(600)
    end

    it 'does not compute duration when completed_at is nil' do
      record = create(:survey_completion_time,
                       survey: survey,
                       user: user,
                       started_at: 10.minutes.ago,
                       completed_at: nil)
      record.compute_duration!
      expect(record.duration_in_seconds).to be_nil
    end
  end

  describe '.completed' do
    it 'returns only records with completed_at set' do
      completed = create(:survey_completion_time,
                          survey: survey,
                          user: user,
                          started_at: 10.minutes.ago,
                          completed_at: Time.zone.now)
      create(:survey_completion_time,
              survey: survey,
              user: create(:user, username: 'other_user'),
              started_at: 5.minutes.ago,
              completed_at: nil)

      expect(described_class.completed).to eq([completed])
    end
  end

  describe 'associations' do
    it 'belongs to survey' do
      record = create(:survey_completion_time, survey: survey, user: user)
      expect(record.survey).to eq(survey)
    end

    it 'belongs to user' do
      record = create(:survey_completion_time, survey: survey, user: user)
      expect(record.user).to eq(user)
    end

    it 'optionally belongs to survey_notification' do
      record = create(:survey_completion_time,
                       survey: survey,
                       user: user,
                       survey_notification_id: nil)
      expect(record.survey_notification).to be_nil
    end
  end
end
