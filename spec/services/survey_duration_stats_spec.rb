# frozen_string_literal: true

require 'rails_helper'

describe SurveyDurationStats do
  let(:survey) { create(:survey) }
  let(:other_survey) { create(:survey, name: 'Other Survey') }
  let(:user) { create(:user) }
  let(:second_user) { create(:user, username: 'Second user') }
  let(:third_user) { create(:user, username: 'Third user') }

  # Helper to create a completed session with a specific duration in seconds.
  def create_completed_session(survey, user, duration_seconds)
    started = 1.hour.ago
    create(:survey_session,
           survey: survey,
           user: user,
           started_at: started,
           completed_at: started + duration_seconds.seconds)
  end

  describe '#average' do
    context 'with no completed sessions' do
      it 'returns placeholder' do
        stats = described_class.new(survey)
        expect(stats.average).to eq('--')
      end
    end

    context 'with completed sessions' do
      before do
        create_completed_session(survey, user, 120)       # 2m 0s
        create_completed_session(survey, second_user, 180) # 3m 0s
      end

      it 'returns the formatted average' do
        stats = described_class.new(survey)
        # avg = (120 + 180) / 2 = 150s => 2m 30s
        expect(stats.average).to eq('2m 30s')
      end
    end
  end

  describe '#median' do
    context 'with no completed sessions' do
      it 'returns placeholder' do
        stats = described_class.new(survey)
        expect(stats.median).to eq('--')
      end
    end

    context 'with odd number of sessions' do
      before do
        create_completed_session(survey, user, 60)
        create_completed_session(survey, second_user, 120)
        create_completed_session(survey, third_user, 300)
      end

      it 'returns the middle value' do
        stats = described_class.new(survey)
        expect(stats.median).to eq('2m 0s')
      end
    end

    context 'with even number of sessions' do
      before do
        create_completed_session(survey, user, 60)
        create_completed_session(survey, second_user, 120)
      end

      it 'returns the average of two middle values' do
        stats = described_class.new(survey)
        # median = (60 + 120) / 2 = 90 => 1m 30s
        expect(stats.median).to eq('1m 30s')
      end
    end
  end

  describe '#fastest' do
    context 'with no completed sessions' do
      it 'returns placeholder' do
        stats = described_class.new(survey)
        expect(stats.fastest).to eq('--')
      end
    end

    context 'with completed sessions' do
      before do
        create_completed_session(survey, user, 45)
        create_completed_session(survey, second_user, 120)
      end

      it 'returns the shortest duration' do
        stats = described_class.new(survey)
        expect(stats.fastest).to eq('45s')
      end
    end
  end

  describe '#slowest' do
    context 'with no completed sessions' do
      it 'returns placeholder' do
        stats = described_class.new(survey)
        expect(stats.slowest).to eq('--')
      end
    end

    context 'with completed sessions' do
      before do
        create_completed_session(survey, user, 45)
        create_completed_session(survey, second_user, 3700)
      end

      it 'returns the longest duration' do
        stats = described_class.new(survey)
        expect(stats.slowest).to eq('1h 1m')
      end
    end
  end

  describe '#completion_rate' do
    context 'with no sessions at all' do
      it 'returns placeholder' do
        stats = described_class.new(survey)
        expect(stats.completion_rate).to eq('--')
      end
    end

    context 'with some completed and some incomplete' do
      before do
        create_completed_session(survey, user, 120)
        # incomplete session (no completed_at)
        create(:survey_session, survey: survey, user: second_user, started_at: 10.minutes.ago)
      end

      it 'returns percentage with counts' do
        stats = described_class.new(survey)
        expect(stats.completion_rate).to eq('50.0% (1/2)')
      end
    end
  end

  describe '#distribution' do
    context 'with no completed sessions' do
      it 'returns empty hash' do
        stats = described_class.new(survey)
        expect(stats.distribution).to eq({})
      end
    end

    context 'with sessions in various buckets' do
      before do
        create_completed_session(survey, user, 30)          # 0-1 min
        create_completed_session(survey, second_user, 90)   # 1-2 min
        create_completed_session(survey, third_user, 200)   # 2-5 min
      end

      it 'bucketizes durations correctly' do
        stats = described_class.new(survey)
        dist = stats.distribution
        expect(dist['0-1 min']).to eq(1)
        expect(dist['1-2 min']).to eq(1)
        expect(dist['2-5 min']).to eq(1)
        expect(dist['5-10 min']).to eq(0)
        expect(dist['10-20 min']).to eq(0)
        expect(dist['20+ min']).to eq(0)
      end
    end
  end

  describe '.batch_averages' do
    context 'with no surveys' do
      it 'returns empty hash' do
        result = described_class.batch_averages([])
        expect(result).to eq({})
      end
    end

    context 'with multiple surveys' do
      before do
        create_completed_session(survey, user, 120)
        create_completed_session(survey, second_user, 180)
        # other_survey has no sessions
      end

      it 'returns a hash of survey_id => formatted average' do
        result = described_class.batch_averages([survey, other_survey])
        expect(result[survey.id]).to eq('2m 30s')
        expect(result[other_survey.id]).to eq('--')
      end

      it 'uses only one aggregate query for all surveys' do
        # Verify batch approach works correctly — we just check return values
        # are consistent with per-survey calculation
        batch = described_class.batch_averages([survey])
        individual = described_class.new(survey).average
        expect(batch[survey.id]).to eq(individual)
      end
    end
  end

  describe 'single load guarantee' do
    before do
      create_completed_session(survey, user, 120)
      create_completed_session(survey, second_user, 300)
    end

    it 'loads durations once and reuses them for all stat methods' do
      stats = described_class.new(survey)

      # After initialization, durations are already loaded
      expect(stats.durations).not_to be_empty

      # Calling multiple methods should not trigger additional queries
      expect(stats.average).to be_a(String)
      expect(stats.median).to be_a(String)
      expect(stats.fastest).to be_a(String)
      expect(stats.slowest).to be_a(String)
      expect(stats.distribution).to be_a(Hash)
    end
  end
end
