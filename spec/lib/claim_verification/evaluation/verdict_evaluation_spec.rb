# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/claim_verification/evaluation/verdict_evaluation"

describe ClaimVerification::Evaluation::VerdictEvaluation do
  let(:dataset) { YAML.safe_load_file(described_class::DEFAULT_DATASET) }
  let(:oracle) do
    answers = dataset.to_h { |kase| [kase['claim'], kase['expected_verdict']] }
    ->(claim:, source_text:) { answers.fetch(claim) } # rubocop:disable Lint/UnusedBlockArgument
  end

  it 'reports perfect accuracy for a verifier matching the labels' do
    evaluation = described_class.new(oracle)
    expect(evaluation.summary[:accuracy]).to eq(1.0)
    expect(evaluation.summary[:total]).to eq(dataset.size)
  end

  it 'covers every verdict class in the seed dataset' do
    expected_verdicts = dataset.map { |kase| kase['expected_verdict'] }.uniq
    expect(expected_verdicts).to contain_exactly(
      'supported', 'partially_supported', 'not_supported', 'contradicted'
    )
  end

  context 'with an imperfect verifier' do
    let(:always_supported) { ->(claim:, source_text:) { :supported } } # rubocop:disable Lint/UnusedBlockArgument
    let(:evaluation) { described_class.new(always_supported) }

    it 'scores accuracy against the labels' do
      supported_count = dataset.count { |kase| kase['expected_verdict'] == 'supported' }
      expect(evaluation.summary[:correct]).to eq(supported_count)
      expect(evaluation.summary[:accuracy]).to be < 1.0
    end

    it 'builds a confusion matrix keyed expected => actual => count' do
      confusion = evaluation.summary[:confusion]
      expect(confusion['contradicted']).to eq('supported' => 2)
    end

    it 'records per-case correctness' do
      incorrect = evaluation.case_results.reject { |result| result[:correct] }
      expect(incorrect).to all(include(actual: 'supported'))
    end
  end

  context 'with a verifier returning a verdict-like object' do
    it 'reads the verdict from the object' do
      verdict_object = Struct.new(:verdict).new(:supported)
      evaluation = described_class.new(->(claim:, source_text:) { verdict_object }) # rubocop:disable Lint/UnusedBlockArgument
      expect(evaluation.case_results.first[:actual]).to eq('supported')
    end
  end
end
