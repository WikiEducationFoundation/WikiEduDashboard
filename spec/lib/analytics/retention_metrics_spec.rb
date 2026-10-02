# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/analytics/retention_metrics"

describe RetentionMetrics do
  def stat(**attrs)
    RetentionStat.new(**attrs)
  end

  context 'with a fully computed course' do
    subject(:metrics) { described_class.new(stats) }

    let(:stats) do
      [
        # first-course participant who survived
        stat(sessions_during: 4, days_to_return: 10, sessions_after: 2, edits_60_90: 6),
        # returning participant with a single edit in the survival window
        stat(sessions_during: 2, days_to_return: 30, sessions_after: 0, edits_60_90: 1,
             prior_course_count: 1),
        # never edited
        stat(sessions_during: 0, days_to_return: 30, sessions_after: 0, edits_60_90: 0),
        # long-term Wikipedian: counted as a participant, excluded from the rest
        stat(sessions_during: 9, days_to_return: 1, sessions_after: 5, edits_60_90: 20,
             long_term_wikipedian: true)
      ]
    end

    it 'counts every participant but leaves long-term Wikipedians out of the rest' do
      expect(metrics.participants).to eq(4)
      expect(metrics.long_term_wikipedians).to eq(1)
      expect(metrics.counted_participants).to eq(3)
      expect(metrics.sessions_during).to eq(6)
    end

    it 'averages over counted participants' do
      expect(metrics.avg_sessions_during).to eq(2.0)
      expect(metrics.avg_days_to_return).to eq(23.3)
      expect(metrics.avg_sessions_after).to eq(0.7)
    end

    it 'reports zero-edit participants and the share of active ones who returned' do
      expect(metrics.zero_edit_participants).to eq(1)
      expect(metrics.editors_after_course).to eq(1)
      expect(metrics.pct_active_editors_after).to eq(50.0)
    end

    it 'counts both survival thresholds and the returning share of each' do
      expect(metrics.any_survival_edits).to eq(2)
      expect(metrics.any_survival_edits_returning).to eq(1)
      expect(metrics.survivors).to eq(1)
      expect(metrics.survivors_returning).to eq(0)
    end
  end

  context 'before the post-course windows have closed' do
    subject(:metrics) { described_class.new([stat(sessions_during: 3), stat(sessions_during: 0)]) }

    it 'reports the during-course figures and nothing else' do
      expect(metrics.sessions_during).to eq(3)
      expect(metrics.zero_edit_participants).to eq(1)
      expect(metrics.editors_after_course).to be_nil
      expect(metrics.pct_active_editors_after).to be_nil
      expect(metrics.avg_days_to_return).to be_nil
      expect(metrics.avg_sessions_after).to be_nil
      expect(metrics.any_survival_edits).to be_nil
      expect(metrics.survivors).to be_nil
    end
  end

  context 'when nothing has been computed' do
    subject(:metrics) { described_class.new([]) }

    it 'has no participants and no figures' do
      expect(metrics.participants).to eq(0)
      expect(metrics.long_term_wikipedians).to be_nil
      expect(metrics.sessions_during).to be_nil
      expect(metrics.zero_edit_participants).to be_nil
      expect(metrics.avg_sessions_during).to be_nil
    end
  end

  context 'when every participant is a long-term Wikipedian' do
    subject(:metrics) do
      described_class.new([stat(sessions_during: 3, long_term_wikipedian: true),
                           stat(sessions_during: 5, long_term_wikipedian: true)])
    end

    it 'counts them and leaves every aggregate blank rather than zero' do
      expect(metrics.participants).to eq(2)
      expect(metrics.long_term_wikipedians).to eq(2)
      expect(metrics.sessions_during).to be_nil
      expect(metrics.zero_edit_participants).to be_nil
    end
  end

  context 'when nobody edited during the course' do
    subject(:metrics) do
      described_class.new([stat(sessions_during: 0, days_to_return: 30, sessions_after: 0)])
    end

    it 'leaves the percentage blank instead of dividing by zero' do
      expect(metrics.editors_after_course).to eq(0)
      expect(metrics.pct_active_editors_after).to be_nil
    end
  end

  context 'across courses at different stages' do
    subject(:metrics) do
      described_class.new([
                            stat(sessions_during: 2, days_to_return: 3, sessions_after: 1,
                                 edits_60_90: 7),
                            stat(sessions_during: 1, days_to_return: 30, sessions_after: 0)
                          ])
    end

    it 'aggregates each figure over the rows that have reached it' do
      expect(metrics.sessions_during).to eq(3)
      expect(metrics.avg_days_to_return).to eq(16.5)
      expect(metrics.survivors).to eq(1)
      expect(metrics.any_survival_edits).to eq(1)
    end
  end
end
