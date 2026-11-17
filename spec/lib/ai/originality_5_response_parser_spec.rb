# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/ai/originality_5_response_parser"

describe Originality5ResponseParser do
  let(:share_link) { 'https://app.originality.ai/share/t6i9x3cn8zwrs7p4' }
  # Shape recorded from the live API on 2026-11-17, with the text fields shortened.
  let(:response) do
    { 'results' => {
      'properties' => { 'id' => 't6i9x3cn8zwrs7p4', 'publicLink' => share_link,
                        'content' => 'the full text', 'formattedContent' => 'the full text' },
      'credits' => { 'used' => 4 },
      'ai' => { 'model' => 'model-5.0-max', 'prediction_label' => 'mixed',
                'ai_assisted_percent' => 58,
                'sentences' => [
                  { 'start_index' => 0, 'end_index' => 230, 'text' => 'first segment',
                    'ai_score' => 0.28 },
                  { 'start_index' => 230, 'end_index' => 400, 'text' => 'second segment',
                    'ai_score' => 1 },
                  { 'start_index' => 400, 'end_index' => 520, 'text' => 'third segment',
                    'ai_score' => 0.54 }
                ] },
      'plagiarism' => { 'error' => 'not selected' }
    } }
  end
  let(:key) { RevisionAiScore::ORIGINALITY_5_MAX_KEY }

  subject(:parser) { described_class.new(key, response) }

  it 'reads the model, verdict and whole-text share' do
    expect(parser.ai_model).to eq('model-5.0-max')
    expect(parser.label).to eq('Mixed')
    expect(parser.document_score).to eq(0.58)
  end

  it 'gives Pangram-compatible scores: the hottest segment and the whole-text share' do
    expect(parser.max_ai_likelihood).to eq(1)
    expect(parser.average_ai_likelihood).to eq(0.58)
    expect(parser.mean_window_score).to be_within(0.0001).of(0.6067)
  end

  it 'normalizes the verdicts and passes unknown ones through' do
    { 'human' => 'Human', 'ai' => 'AI', 'likely_ai' => 'likely_ai' }.each do |raw, label|
      response['results']['ai']['prediction_label'] = raw
      expect(described_class.new(key, response).label).to eq(label)
    end
  end

  it 'fills the shared summary' do
    expect(parser.summary).to include(
      'check_type' => 'Originality 5.0 Max', 'vendor' => 'originality',
      'model_version' => 'model-5.0-max', 'label' => 'Mixed', 'document_score' => 0.58,
      'max_score' => 1, 'window_count' => 3, 'windows_above_0_5' => 2, 'windows_above_0_9' => 1,
      'report_url' => share_link
    )
  end

  it 'strips the text without changing the response' do
    cleaned = parser.clean_result

    expect(cleaned['results']['properties']).not_to have_key('content')
    expect(cleaned['results']['properties']).not_to have_key('formattedContent')
    expect(cleaned['results']['ai']['sentences'].first)
      .to eq('start_index' => 0, 'end_index' => 230, 'ai_score' => 0.28)
    expect(response['results']['ai']['sentences'].first['text']).to eq('first segment')
  end

  it 'handles a response with no segments' do
    response['results']['ai']['sentences'] = []

    expect(parser.max_ai_likelihood).to be_nil
    expect(parser.mean_window_score).to be_nil
    expect(parser.summary['window_count']).to eq(0)
  end
end
