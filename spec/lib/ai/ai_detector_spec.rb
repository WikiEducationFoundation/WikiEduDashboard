# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/ai/ai_detector"

describe AiDetector do
  describe '.keys' do
    it 'lists every selectable detector by its check_type' do
      expect(described_class.keys).to eq(['Pangram 4.1', 'Originality 5.0', 'Originality 5.0 Max'])
    end

    it 'leaves out the production alerting key, which follows any Pangram version' do
      expect(described_class.keys).not_to include(RevisionAiScore::PANGRAM_V4_KEY)
      expect(described_class).to be_registered(RevisionAiScore::PANGRAM_V4_KEY)
      expect(described_class).not_to be_selectable(RevisionAiScore::PANGRAM_V4_KEY)
    end

    it 'no longer offers retired detectors' do
      retired = [RevisionAiScore::PANGRAM_V3_KEY, RevisionAiScore::ORIGINALITY_TURBO_KEY,
                 RevisionAiScore::ORIGINALITY_ACADEMIC_KEY, RevisionAiScore::ORIGINALITY_LITE_102_KEY,
                 RevisionAiScore::ORIGINALITY_AI_ALLOWANCE_15_KEY,
                 RevisionAiScore::ORIGINALITY_AI_ALLOWANCE_40_KEY]
      retired.each { |key| expect(described_class).not_to be_registered(key) }
    end
  end

  describe '.for' do
    it 'raises for an unregistered key' do
      expect { described_class.for('GPTZero') }.to raise_error(AiDetector::UnknownDetector)
    end

    it 'returns the same detector for repeated lookups' do
      expect(described_class.for('Pangram 4.1')).to be(described_class.for('Pangram 4.1'))
    end

    it 'builds the matching client and vendor' do
      detector = described_class.for(RevisionAiScore::ORIGINALITY_5_MAX_KEY)

      expect(detector.vendor.name).to eq(:originality)
      expect(detector).not_to be_pangram
      expect(detector.client).to be_a(OriginalityApi)
      expect(detector.client.expected_model).to eq('model-5.0-max')
    end

    it 'pins Pangram 4.1 to its version and leaves the production key unpinned' do
      expect(described_class.for(RevisionAiScore::PANGRAM_V4_1_KEY)).to be_pangram
      expect(described_class.for(RevisionAiScore::PANGRAM_V4_1_KEY).client.expected_version)
        .to eq('4.1')
      expect(described_class.for(RevisionAiScore::PANGRAM_V4_KEY).client.expected_version).to be_nil
    end
  end

  describe '.parser_class_for' do
    it 'reads stored rows of current and retired detectors' do
      expect(described_class.parser_class_for('Originality 5.0')).to eq(Originality5ResponseParser)
      expect(described_class.parser_class_for('Originality AI Allowance 40'))
        .to eq(OriginalityResponseParser)
      expect(described_class.parser_class_for('Pangram 3')).to eq(PangramResponseParser)
      expect(described_class.parser_class_for('Pangram 4.0')).to eq(PangramResponseParser)
      expect(described_class.parser_class_for('GPTZero')).to be_nil
    end
  end

  describe 'vendor policy' do
    let(:pangram) { described_class.for(RevisionAiScore::PANGRAM_V4_1_KEY) }
    let(:model_5) { described_class.for(RevisionAiScore::ORIGINALITY_5_KEY) }
    let(:model_5_max) { described_class.for(RevisionAiScore::ORIGINALITY_5_MAX_KEY) }

    it 'names the partial that renders each vendor' do
      expect(pangram.partial).to eq('ai_tools/pangram')
      expect(model_5_max.partial).to eq('ai_tools/originality')
    end

    it 'exposes the minimum input only for vendors that have one' do
      expect(pangram.min_words).to be_nil
      expect(model_5.min_words).to eq(50)
    end

    it 'estimates credits per vendor, and nil when unmetered' do
      expect(pangram.estimated_credits([480, 30])).to be_nil
      expect(model_5.estimated_credits([480, 30])).to eq(6)
      expect(model_5_max.estimated_credits([480, 30])).to eq(6)
    end

    it 'lists every error class a detector call can recover from' do
      expect(described_class.recoverable_errors)
        .to include(Faraday::Error, JSON::ParserError, PangramApi::Error, OriginalityApi::Error)
    end

    it 'lists the errors that mean a vendor changed models under a pinned detector' do
      expect(described_class.model_mismatch_errors)
        .to contain_exactly(PangramApi::ModelMismatch, OriginalityApi::ModelMismatch)
    end

    it 'reads balances for the vendors present that report one' do
      allow(OriginalityApi).to receive(:credit_balance).and_return(127_755)

      expect(described_class.credit_balances([pangram])).to eq({})
      expect(described_class.credit_balances([pangram, model_5, model_5_max]))
        .to eq('originality_credit_balance' => 127_755)
    end

    it 'reports a failed balance lookup as its message' do
      allow(OriginalityApi).to receive(:credit_balance)
        .and_raise(OriginalityApi::RequestError.new(503, 'down'))

      expect(described_class.credit_balances([model_5])['originality_credit_balance'])
        .to include('HTTP 503')
    end
  end

  describe '#score' do
    let(:detector) { described_class.for(RevisionAiScore::PANGRAM_V4_1_KEY) }
    let(:response) do
      { 'version' => '4.1', 'prediction_short' => 'AI', 'fraction_ai' => 1.0,
        'fraction_ai_assisted' => 0.0, 'fraction_human' => 0.0,
        'windows' => [{ 'ai_assistance_score' => 0.95 }],
        'dashboard_link' => 'https://www.pangram.com/history/abc' }
    end

    it 'sends the text to the client and wraps the response in the parser' do
      allow(detector.client).to receive(:inference).with('some text').and_return(response)

      parser = detector.score('some text')

      expect(parser).to be_a(PangramResponseParser)
      expect(parser.summary).to include('check_type' => 'Pangram 4.1', 'vendor' => 'pangram',
                                        'max_score' => 0.95, 'model_version' => '4.1')
    end
  end

  describe '#parse' do
    it 'wraps a stored response without calling the API' do
      detector = described_class.for(RevisionAiScore::ORIGINALITY_5_KEY)
      stored = { 'results' => { 'ai' => { 'model' => 'model-5.0', 'prediction_label' => 'human',
                                          'ai_assisted_percent' => 1,
                                          'sentences' => [{ 'ai_score' => 0.01 }] } } }

      expect(detector.client).not_to receive(:inference)
      expect(detector.parse(stored).summary).to include('label' => 'Human', 'max_score' => 0.01)
    end
  end
end
