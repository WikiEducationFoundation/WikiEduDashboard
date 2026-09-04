# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/ai/pangram_response_parser"

describe PangramResponseParser do
  let(:share_link) { 'https://www.pangram.com/history/7980768b-0b15-4d42-ad62-30ba8cf0e92f' }
  let(:v3_response) do
    { 'text' => 'example',
      'version' => '3.3.2',
      'headline' => 'Fully AI Generated',
      'prediction' => 'We are confident that this document is fully AI-generated',
      'prediction_short' => 'AI',
      'fraction_ai' => 0.8,
      'fraction_ai_assisted' => 0.2,
      'fraction_human' => 0.0,
      'num_ai_segments' => 2,
      'num_ai_assisted_segments' => 1,
      'num_human_segments' => 0,
      'windows' =>
        [{ 'text' => 'first window', 'label' => 'AI-Generated',
           'ai_assistance_score' => 1.0, 'confidence' => 'High', 'word_count' => 359 },
         { 'text' => 'second window', 'label' => 'AI-Generated',
           'ai_assistance_score' => 1.0, 'confidence' => 'High', 'word_count' => 358 },
         { 'text' => 'third window', 'label' => 'Lightly AI-Assisted',
           'ai_assistance_score' => 0.25, 'confidence' => 'Medium', 'word_count' => 72 }],
      'dashboard_link' => share_link }
  end
  # Pangram 4 keeps the same field names and adds stage, is_humanized and humanizer_score.
  let(:v4_response) do
    { 'stage' => 'STAGE_SUCCESS',
      'text' => 'example',
      'version' => '4.0',
      'headline' => 'AI Generated',
      'prediction' => 'We believe that this entire text is AI.',
      'prediction_short' => 'AI',
      'fraction_ai' => 0.8,
      'fraction_ai_assisted' => 0.2,
      'fraction_human' => 0.0,
      'num_ai_segments' => 2,
      'num_ai_assisted_segments' => 1,
      'num_human_segments' => 0,
      'windows' =>
        [{ 'text' => 'first window', 'label' => 'AI-Generated',
           'ai_assistance_score' => 1.0, 'confidence' => 'High', 'word_count' => 359,
           'is_humanized' => true, 'humanizer_score' => 0.97 },
         { 'text' => 'second window', 'label' => 'AI-Generated',
           'ai_assistance_score' => 1.0, 'confidence' => 'High', 'word_count' => 358,
           'is_humanized' => false, 'humanizer_score' => 0.1 },
         { 'text' => 'third window', 'label' => 'AI-Assisted',
           'ai_assistance_score' => 0.25, 'confidence' => 'Medium', 'word_count' => 72,
           'is_humanized' => false, 'humanizer_score' => 0.0 }],
      'dashboard_link' => share_link }
  end

  describe '#pangram_details' do
    context 'with a Pangram 3 response' do
      subject(:details) do
        described_class.new(RevisionAiScore::PANGRAM_V3_KEY, v3_response).pangram_details
      end

      it 'maps the response onto the alert details structure' do
        expect(details).to eq(
          pangram_prediction: 'We are confident that this document is fully AI-generated',
          headline_result: 'Fully AI Generated',
          average_ai_likelihood: 0.75,
          max_ai_likelihood: 1.0,
          fraction_human_content: 0.0,
          fraction_ai_content: 0.8,
          fraction_mixed_content: 0.2,
          window_likelihoods: [1.0, 1.0, 0.25],
          predicted_ai_window_count: 2,
          pangram_share_link: share_link,
          pangram_version: '3.3.2'
        )
      end

      it 'omits the humanizer fields' do
        expect(details).not_to have_key(:humanized_window_count)
        expect(details).not_to have_key(:max_humanizer_score)
      end
    end

    context 'with a Pangram 4 response' do
      subject(:details) do
        described_class.new(RevisionAiScore::PANGRAM_V4_KEY, v4_response).pangram_details
      end

      it 'keeps the same likelihood and fraction fields' do
        expect(details).to include(
          headline_result: 'AI Generated',
          average_ai_likelihood: 0.75,
          max_ai_likelihood: 1.0,
          fraction_ai_content: 0.8,
          fraction_mixed_content: 0.2,
          predicted_ai_window_count: 2,
          pangram_version: '4.0'
        )
      end

      it 'adds the humanizer fields' do
        expect(details).to include(humanized_window_count: 1, max_humanizer_score: 0.97)
      end
    end
  end

  describe '#clean_result' do
    it 'removes the text from the response and from each window' do
      cleaned = described_class.new(RevisionAiScore::PANGRAM_V4_KEY, v4_response).clean_result

      expect(cleaned).not_to have_key('text')
      expect(cleaned['windows'].map(&:keys).flatten).not_to include('text')
      expect(cleaned['windows'].first).to include('is_humanized' => true, 'humanizer_score' => 0.97)
      expect(cleaned['stage']).to eq('STAGE_SUCCESS')
    end

    it 'does not mutate the original response' do
      described_class.new(RevisionAiScore::PANGRAM_V3_KEY, v3_response).clean_result

      expect(v3_response['text']).to eq('example')
      expect(v3_response['windows'].first['text']).to eq('first window')
    end
  end

  describe '#summary' do
    it 'fills every DetectorSummary key for a Pangram 3 response' do
      summary = described_class.new(RevisionAiScore::PANGRAM_V3_KEY, v3_response).summary

      expect(summary.keys).to eq(DetectorSummary::KEYS)
      expect(summary).to include(
        'check_type' => 'Pangram 3', 'vendor' => 'pangram', 'model_version' => '3.3.2',
        'label' => 'AI', 'document_score' => nil, 'max_score' => 1.0, 'mean_window_score' => 0.75,
        'window_count' => 3, 'windows_above_0_5' => 2, 'windows_above_0_9' => 2,
        'fraction_ai' => 0.8, 'fraction_mixed' => 0.2, 'fraction_human' => 0.0,
        'humanized_window_count' => nil, 'max_humanizer_score' => nil, 'report_url' => share_link
      )
    end

    it 'includes the humanizer counts for a Pangram 4 response' do
      summary = described_class.new(RevisionAiScore::PANGRAM_V4_KEY, v4_response).summary

      expect(summary).to include('model_version' => '4.0', 'humanized_window_count' => 1,
                                 'max_humanizer_score' => 0.97)
    end
  end

  describe 'version predicates' do
    it 'reports which model produced the response' do
      expect(described_class.new(RevisionAiScore::PANGRAM_V3_KEY, v3_response)).to be_pangram_v3
      expect(described_class.new(RevisionAiScore::PANGRAM_V4_KEY, v4_response)).to be_pangram_v4
      expect(described_class.new(RevisionAiScore::PANGRAM_V4_KEY, v4_response)).not_to be_pangram_v3
    end
  end
end
