# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/ai/originality_response_parser"

describe OriginalityResponseParser do
  def block(text, fake)
    { 'text' => text,
      'result' => { 'fake' => fake, 'real' => (1 - fake).round(3), 'status' => 'success' } }
  end

  let(:share_link) { 'https://app.originality.ai/share/x3vze1buqfni7ogk' }
  # Shape recorded from the live API on 2026-09-03, with the text fields shortened.
  let(:classic_response) do
    { 'results' => {
      'properties' => { 'id' => 'x3vze1buqfni7ogk', 'publicLink' => share_link,
                        'content' => 'the full text', 'formattedContent' => 'the full text' },
      'credits' => { 'used' => 1 },
      'ai' => { 'aiModel' => 'turbo',
                'classification' => { 'AI' => 1, 'Original' => 0 },
                'confidence' => { 'AI' => 0.9989, 'Original' => 0.0011 },
                'blocks' => [block('first block', 0.95), block('second block', 0.6),
                             block('third block', 0.1)] },
      'plagiarism' => { 'error' => 'not selected' },
      'aiAllowance' => { 'error' => 'not selected' }
    } }
  end
  # In allowance mode results.ai carries the allowance result and
  # results.aiAllowance repeats it under the threshold.
  let(:allowance_response) do
    { 'results' => {
      'properties' => { 'publicLink' => share_link, 'content' => 'the full text' },
      'ai' => { 'aiModel' => 'allowance-40%',
                'classification' => { 'AI' => 0, 'Original' => 1 },
                'confidence' => { 'AI' => 0.0299, 'Original' => 0.9701 },
                'blocks' => [block('first block', 0.0), block('second block', 0.448)] },
      'aiAllowance' => { '40' => {
        'confidence' => { 'AI' => 0.0299, 'Original' => 0.9701 },
        'blocks' => [block('first block', 0.0), block('second block', 0.448)]
      } }
    } }
  end

  describe 'compatibility scores' do
    subject(:parser) { described_class.new(RevisionAiScore::ORIGINALITY_TURBO_KEY, classic_response) }

    it 'uses the highest block score as the max likelihood' do
      expect(parser.max_ai_likelihood).to eq(0.95)
    end

    it 'keeps the whole-text confidence as the average likelihood' do
      expect(parser.average_ai_likelihood).to eq(0.9989)
    end

    it 'exposes the mean of block scores separately' do
      expect(parser.mean_window_score).to be_within(0.0001).of(0.55)
    end
  end

  describe '#summary' do
    it 'fills every DetectorSummary key for a classic model' do
      summary = described_class.new(RevisionAiScore::ORIGINALITY_TURBO_KEY, classic_response)
                               .summary

      expect(summary.keys).to eq(DetectorSummary::KEYS)
      expect(summary).to include(
        'check_type' => 'Originality Turbo', 'vendor' => 'originality', 'model_version' => 'turbo',
        'label' => 'AI', 'document_score' => 0.9989, 'max_score' => 0.95,
        'window_count' => 3, 'windows_above_0_5' => 2, 'windows_above_0_9' => 1,
        'fraction_ai' => nil, 'humanized_window_count' => nil, 'report_url' => share_link
      )
    end

    it 'reads an allowance-mode response from results.ai' do
      summary = described_class.new(RevisionAiScore::ORIGINALITY_AI_ALLOWANCE_40_KEY,
                                    allowance_response).summary

      expect(summary).to include(
        'check_type' => 'Originality AI Allowance 40', 'model_version' => 'allowance-40%',
        'label' => 'Original', 'document_score' => 0.0299, 'max_score' => 0.448,
        'window_count' => 2, 'windows_above_0_5' => 0
      )
    end
  end

  describe '#clean_result' do
    it 'removes the stored text from the properties and every block' do
      cleaned = described_class.new(RevisionAiScore::ORIGINALITY_TURBO_KEY, classic_response)
                               .clean_result

      expect(cleaned['results']['properties']).not_to have_key('content')
      expect(cleaned['results']['properties']).not_to have_key('formattedContent')
      expect(cleaned['results']['properties']['publicLink']).to eq(share_link)
      expect(cleaned['results']['ai']['blocks'].map(&:keys).flatten).not_to include('text')
      expect(cleaned['results']['ai']['blocks'].first['result']['fake']).to eq(0.95)
    end

    it 'also strips text from the allowance blocks' do
      cleaned = described_class.new(RevisionAiScore::ORIGINALITY_AI_ALLOWANCE_40_KEY,
                                    allowance_response).clean_result

      blocks = cleaned['results']['aiAllowance']['40']['blocks']
      expect(blocks.map(&:keys).flatten).not_to include('text')
      expect(blocks.last['result']['fake']).to eq(0.448)
    end

    it 'does not mutate the original response' do
      described_class.new(RevisionAiScore::ORIGINALITY_TURBO_KEY, classic_response).clean_result

      expect(classic_response['results']['properties']['content']).to eq('the full text')
      expect(classic_response['results']['ai']['blocks'].first['text']).to eq('first block')
    end
  end
end
