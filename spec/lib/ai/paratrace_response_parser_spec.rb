# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/ai/paratrace_response_parser"

describe ParatraceResponseParser do
  let(:key) { RevisionAiScore::PARATRACE_V10_KEY }
  let(:response) do
    { 'detector_version' => 'v10-ft-g', 'credits_charged' => 4, 'credits_remaining' => 995,
      'documents' => [{ 'document' => 'text', 'probability' => 0.62, 'is_ai' => true,
                        'verdict' => 'mixed', 'ai_fraction' => 0.4, 'category' => 'ai_assisted',
                        'n_windows' => 3,
                        'windows' => [{ 'start' => 0, 'end' => 900, 'probability' => 0.05 },
                                      { 'start' => 900, 'end' => 1800, 'probability' => 0.97 },
                                      { 'start' => 1800, 'end' => 2400, 'probability' => 0.6 }] }] }
  end

  subject(:parser) { described_class.new(key, response) }

  it 'reads the verdict, whole-text probability and windows' do
    expect(parser.label).to eq('Mixed')
    expect(parser.document_score).to eq(0.62)
    expect(parser.average_ai_likelihood).to eq(0.62)
    expect(parser.max_ai_likelihood).to eq(0.97)
    expect(parser.mean_window_score).to be_within(0.0001).of(0.54)
  end

  it 'fills the shared summary' do
    expect(parser.summary).to include(
      'check_type' => 'ParaTrace v10', 'vendor' => 'paratrace', 'model_version' => 'v10-ft-g',
      'label' => 'Mixed', 'document_score' => 0.62, 'max_score' => 0.97, 'window_count' => 3,
      'windows_above_0_5' => 2, 'windows_above_0_9' => 1, 'fraction_ai' => 0.4
    )
  end

  it 'normalizes the verdicts and passes unknown ones through' do
    { 'human' => 'Human', 'ai' => 'AI', 'unsure' => 'unsure' }.each do |raw, label|
      response['documents'].first['verdict'] = raw
      expect(described_class.new(key, response).label).to eq(label)
    end
  end

  it 'handles a text with nothing left after cleaning' do
    response['documents'].first.merge!('probability' => nil, 'verdict' => nil, 'windows' => [])

    expect(parser.average_ai_likelihood).to be_nil
    expect(parser.max_ai_likelihood).to be_nil
    expect(parser.mean_window_score).to be_nil
  end
end
