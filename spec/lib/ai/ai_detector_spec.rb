# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/ai/ai_detector"

describe AiDetector do
  describe '.keys' do
    it 'lists every selectable detector by its check_type' do
      expect(described_class.keys).to eq(
        ['Pangram 3', 'Pangram 4', 'Originality Lite 1.0.2', 'Originality Turbo',
         'Originality Academic', 'Originality AI Allowance 15', 'Originality AI Allowance 40']
      )
    end

    it 'does not offer the retired Lite 1.0.0 model' do
      expect(described_class.keys).not_to include(RevisionAiScore::ORIGINALITY_LITE_KEY)
    end
  end

  describe '.for' do
    it 'raises for an unregistered key' do
      expect { described_class.for('GPTZero') }.to raise_error(AiDetector::UnknownDetector)
    end

    it 'returns the same detector for repeated lookups' do
      expect(described_class.for('Pangram 4')).to be(described_class.for('Pangram 4'))
    end

    it 'builds the matching client and vendor' do
      detector = described_class.for(RevisionAiScore::ORIGINALITY_AI_ALLOWANCE_40_KEY)

      expect(detector.vendor.name).to eq(:originality)
      expect(detector).not_to be_pangram
      expect(detector.client).to be_a(OriginalityApi)
      expect(detector.client.expected_model).to eq('allowance-40%')
    end

    it 'marks the Pangram detectors' do
      expect(described_class.for(RevisionAiScore::PANGRAM_V4_KEY)).to be_pangram
      expect(described_class.for(RevisionAiScore::PANGRAM_V4_KEY).client).to be_a(PangramApi)
    end
  end

  describe 'vendor policy' do
    let(:pangram) { described_class.for(RevisionAiScore::PANGRAM_V4_KEY) }
    let(:turbo) { described_class.for(RevisionAiScore::ORIGINALITY_TURBO_KEY) }
    let(:allowance) { described_class.for(RevisionAiScore::ORIGINALITY_AI_ALLOWANCE_15_KEY) }

    it 'names the partial that renders each vendor' do
      expect(pangram.partial).to eq('ai_tools/pangram')
      expect(allowance.partial).to eq('ai_tools/originality')
    end

    it 'exposes the minimum input only for vendors that have one' do
      expect(pangram.min_words).to be_nil
      expect(turbo.min_words).to eq(50)
    end

    it 'estimates credits per vendor, doubled for allowance scans, and nil when unmetered' do
      expect(pangram.estimated_credits([480, 30])).to be_nil
      expect(turbo.estimated_credits([480, 30])).to eq(6)
      expect(allowance.estimated_credits([480, 30])).to eq(12)
    end

    it 'lists every error class a detector call can recover from' do
      expect(described_class.recoverable_errors)
        .to include(Faraday::Error, JSON::ParserError, PangramApi::Error, OriginalityApi::Error)
    end

    it 'reads balances for the vendors present that report one' do
      allow(OriginalityApi).to receive(:credit_balance).and_return(14_488)

      expect(described_class.credit_balances([pangram])).to eq({})
      expect(described_class.credit_balances([pangram, turbo, allowance]))
        .to eq('originality_credit_balance' => 14_488)
    end

    it 'reports a failed balance lookup as its message' do
      allow(OriginalityApi).to receive(:credit_balance)
        .and_raise(OriginalityApi::RequestError.new(503, 'down'))

      expect(described_class.credit_balances([turbo])['originality_credit_balance'])
        .to include('HTTP 503')
    end
  end

  describe '#score' do
    let(:detector) { described_class.for(RevisionAiScore::PANGRAM_V3_KEY) }
    let(:response) do
      { 'version' => '3.3.2', 'prediction_short' => 'AI', 'fraction_ai' => 1.0,
        'fraction_ai_assisted' => 0.0, 'fraction_human' => 0.0,
        'windows' => [{ 'ai_assistance_score' => 0.95 }],
        'dashboard_link' => 'https://www.pangram.com/history/abc' }
    end

    it 'sends the text to the client and wraps the response in the parser' do
      allow(detector.client).to receive(:inference).with('some text').and_return(response)

      parser = detector.score('some text')

      expect(parser).to be_a(PangramResponseParser)
      expect(parser.summary).to include('check_type' => 'Pangram 3', 'vendor' => 'pangram',
                                        'max_score' => 0.95, 'model_version' => '3.3.2')
    end
  end

  describe '#parse' do
    it 'wraps a stored response without calling the API' do
      detector = described_class.for(RevisionAiScore::ORIGINALITY_TURBO_KEY)
      stored = { 'results' => { 'ai' => { 'aiModel' => 'turbo',
                                          'classification' => { 'AI' => 0, 'Original' => 1 },
                                          'confidence' => { 'AI' => 0.01, 'Original' => 0.99 },
                                          'blocks' => [{ 'result' => { 'fake' => 0.01 } }] } } }

      expect(detector.client).not_to receive(:inference)
      expect(detector.parse(stored).summary).to include('label' => 'Original', 'max_score' => 0.01)
    end
  end
end
