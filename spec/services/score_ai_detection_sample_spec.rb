# frozen_string_literal: true

require 'rails_helper'

describe ScoreAiDetectionSample do
  let(:pangram_v4) { RevisionAiScore::PANGRAM_V4_KEY }
  let(:allowance_15) { RevisionAiScore::ORIGINALITY_AI_ALLOWANCE_15_KEY }
  let(:long_text) { (['Prose about a village and its river crossing.'] * 60).join(' ') }
  # Enough characters to be sampled, too few words for Originality.
  let(:short_text) { ('Supercalifragilisticexpialidocious ' * 30).strip }
  let(:enwiki) { Wiki.get_or_create(language: 'en', project: 'wikipedia') }
  let!(:long_unit) do
    AiDetectionSample.create!(sample_name: 'test', plain_text: long_text, wiki_id: enwiki.id,
                              rev_id: 11, url: 'https://en.wikipedia.org/w/index.php?diff=11')
  end
  let!(:short_unit) do
    AiDetectionSample.create!(sample_name: 'test', plain_text: short_text, rev_id: 12)
  end
  let(:pangram_response) do
    { 'version' => '4.0', 'prediction_short' => 'AI', 'fraction_ai' => 1.0,
      'fraction_ai_assisted' => 0.0, 'fraction_human' => 0.0, 'text' => long_text,
      'windows' => [{ 'text' => 'w', 'ai_assistance_score' => 0.97, 'is_humanized' => false }],
      'dashboard_link' => 'https://www.pangram.com/history/abc' }
  end
  let(:originality_response) do
    { 'results' => { 'properties' => { 'publicLink' => 'https://app.originality.ai/share/x' },
                     'ai' => { 'aiModel' => 'allowance-15%',
                               'classification' => { 'AI' => 0, 'Original' => 1 },
                               'confidence' => { 'AI' => 0.02, 'Original' => 0.98 },
                               'blocks' => [{ 'text' => 'b', 'result' => { 'fake' => 0.3 } }] } } }
  end
  let(:pangram_client) { AiDetector.for(pangram_v4).client }
  let(:originality_client) { AiDetector.for(allowance_15).client }

  describe 'dry run' do
    it 'reports pending work and credits without calling any detector' do
      allow(OriginalityApi).to receive(:credit_balance).and_return(14_488)
      expect(pangram_client).not_to receive(:inference)
      expect(originality_client).not_to receive(:inference)

      report = described_class.new(sample_name: 'test', detectors: [pangram_v4, allowance_15],
                                   dry_run: true).report

      expect(report[pangram_v4]).to eq(pending_units: 2, pending_words: 510,
                                       estimated_credits: nil)
      # 480 words → 5 credits per check, doubled for an allowance scan; the short unit is excluded.
      expect(report[allowance_15]).to eq(pending_units: 1, pending_words: 480,
                                         estimated_credits: 10)
      expect(report['originality_credit_balance']).to eq(14_488)
    end
  end

  describe 'scoring' do
    before do
      allow(pangram_client).to receive(:inference).and_return(pangram_response)
      allow(originality_client).to receive(:inference).and_return(originality_response)
    end

    it 'stores one comparison row per unit and detector, skipping too-short Originality units' do
      scorer = described_class.new(sample_name: 'test', detectors: [pangram_v4, allowance_15])

      expect(scorer.report).to eq(pangram_v4 => { scored: 2, failed: 0 },
                                  allowance_15 => { scored: 1, failed: 0 })
      expect(originality_client).to have_received(:inference).with(long_text).once

      score = RevisionAiScore.find_by(sample_id: long_unit.id, check_type: pangram_v4)
      expect(score).to have_attributes(check_origin: 'detector_comparison', revision_id: 11,
                                       wiki_id: enwiki.id, url: long_unit.url,
                                       max_ai_likelihood: 0.97, avg_ai_likelihood: 0.97)
      expect(score.details).not_to have_key('text')
      expect(score.details['windows'].first).not_to have_key('text')

      originality = RevisionAiScore.find_by(sample_id: long_unit.id, check_type: allowance_15)
      expect(originality.max_ai_likelihood).to eq(0.3)
      expect(originality.avg_ai_likelihood).to eq(0.02)
      expect(RevisionAiScore.where(sample_id: short_unit.id).pluck(:check_type)).to eq([pangram_v4])
    end

    it 'does not re-score units on a second run' do
      described_class.new(sample_name: 'test', detectors: [pangram_v4])
      described_class.new(sample_name: 'test', detectors: [pangram_v4])

      expect(pangram_client).to have_received(:inference).twice
      expect(RevisionAiScore.count).to eq(2)
    end

    it 'honors the limit' do
      described_class.new(sample_name: 'test', detectors: [pangram_v4], limit: 1)

      expect(RevisionAiScore.pluck(:sample_id)).to eq([long_unit.id])
    end
  end

  describe 'failures' do
    it 'records the error, then retries and updates the same row on the next run' do
      call_count = 0
      allow(pangram_client).to receive(:inference) do
        call_count += 1
        raise PangramApi::TaskTimeout, 'unfinished after 60s' if call_count <= 2

        pangram_response
      end

      failed = described_class.new(sample_name: 'test', detectors: [pangram_v4])
      expect(failed.report[pangram_v4]).to eq(scored: 0, failed: 2)
      row = RevisionAiScore.find_by(sample_id: long_unit.id, check_type: pangram_v4)
      expect(row.avg_ai_likelihood).to be_nil
      expect(row.details).to eq('error' => 'PangramApi::TaskTimeout',
                                'message' => 'unfinished after 60s')

      retried = described_class.new(sample_name: 'test', detectors: [pangram_v4])
      expect(retried.report[pangram_v4]).to eq(scored: 2, failed: 0)
      expect(RevisionAiScore.count).to eq(2)
      expect(row.reload.max_ai_likelihood).to eq(0.97)
    end
  end
end
