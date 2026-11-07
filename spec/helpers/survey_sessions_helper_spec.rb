# frozen_string_literal: true

require 'rails_helper'

describe SurveySessionsHelper, type: :helper do
  let(:survey) { create(:survey) }
  let(:user) { create(:user) }
  let(:second_user) { create(:user, username: 'Second user') }
  let(:third_user) { create(:user, username: 'Third user') }

  def create_completed_session(survey, user, duration_seconds)
    started = 1.hour.ago
    create(:survey_session,
           survey: survey,
           user: user,
           started_at: started,
           completed_at: started + duration_seconds.seconds)
  end

  describe '#average_duration' do
    it 'returns placeholder when no sessions exist' do
      expect(helper.average_duration(survey)).to eq('--')
    end

    it 'returns formatted average' do
      create_completed_session(survey, user, 120)
      create_completed_session(survey, second_user, 180)
      expect(helper.average_duration(survey)).to eq('2m 30s')
    end
  end

  describe '#median_duration' do
    it 'returns placeholder when no sessions exist' do
      expect(helper.median_duration(survey)).to eq('--')
    end

    it 'returns middle value for odd count' do
      create_completed_session(survey, user, 60)
      create_completed_session(survey, second_user, 120)
      create_completed_session(survey, third_user, 300)
      expect(helper.median_duration(survey)).to eq('2m 0s')
    end

    it 'returns average of two middle values for even count' do
      create_completed_session(survey, user, 60)
      create_completed_session(survey, second_user, 120)
      # median = (60 + 120) / 2 = 90 => 1m 30s
      expect(helper.median_duration(survey)).to eq('1m 30s')
    end
  end

  describe '#fastest_duration' do
    it 'returns placeholder when no sessions exist' do
      expect(helper.fastest_duration(survey)).to eq('--')
    end

    it 'returns the shortest duration' do
      create_completed_session(survey, user, 45)
      create_completed_session(survey, second_user, 120)
      expect(helper.fastest_duration(survey)).to eq('45s')
    end
  end

  describe '#slowest_duration' do
    it 'returns placeholder when no sessions exist' do
      expect(helper.slowest_duration(survey)).to eq('--')
    end

    it 'returns the longest duration formatted with hours' do
      create_completed_session(survey, user, 45)
      create_completed_session(survey, second_user, 3700)
      expect(helper.slowest_duration(survey)).to eq('1h 1m')
    end
  end

  describe '#completion_rate' do
    it 'returns placeholder when no sessions exist' do
      expect(helper.completion_rate(survey)).to eq('--')
    end

    it 'returns percentage with counts' do
      create_completed_session(survey, user, 120)
      create(:survey_session, survey: survey, user: second_user, started_at: 10.minutes.ago)
      expect(helper.completion_rate(survey)).to eq('50.0% (1/2)')
    end
  end

  describe '#duration_distribution' do
    it 'returns empty hash when no sessions exist' do
      expect(helper.duration_distribution(survey)).to eq({})
    end

    it 'bucketizes durations correctly' do
      create_completed_session(survey, user, 30)        # 0-1 min
      create_completed_session(survey, second_user, 90)  # 1-2 min
      create_completed_session(survey, third_user, 200)  # 2-5 min
      dist = helper.duration_distribution(survey)
      expect(dist['0-1 min']).to eq(1)
      expect(dist['1-2 min']).to eq(1)
      expect(dist['2-5 min']).to eq(1)
      expect(dist['5-10 min']).to eq(0)
    end
  end

  describe '#batch_average_duration' do
    it 'reads from @survey_avg_durations when available' do
      assign(:survey_avg_durations, { survey.id => '3m 15s' })
      expect(helper.batch_average_duration(survey)).to eq('3m 15s')
    end

    it 'falls back to average_duration when @survey_avg_durations is not set' do
      create_completed_session(survey, user, 120)
      create_completed_session(survey, second_user, 180)
      expect(helper.batch_average_duration(survey)).to eq('2m 30s')
    end
  end
end
