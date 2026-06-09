# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/claim_verification/claim"

describe VerifyClaimAgainstSource do
  let(:claim) do
    ClaimVerification::Claim.new(
      sentence: 'The library opened in 1923.',
      ref_ids: ['cite_note-1'],
      context: 'The library is on Main Street. The library opened in 1923.'
    )
  end

  context 'with a fetched source' do
    let(:adapter) { instance_double(Llm::AnthropicAdapter) }
    let(:judge_json) do
      { 'verdict' => 'supported',
        'quote' => 'first opened its doors to readers in 1923',
        'explanation' => 'The source states the opening year directly.' }
    end
    let(:prompts) { [] }

    before do
      allow(Llm::Client).to receive(:adapter).and_return(adapter)
      allow(adapter).to receive(:complete) do |system:, user:, json_schema:|
        prompts << { system:, user:, json_schema: }
        Llm::Response.new(text: judge_json.to_json, json: judge_json,
                          model: 'claude-opus-4-8',
                          usage: { input_tokens: 200, output_tokens: 40 })
      end
    end

    let(:verdict) do
      described_class.new(claim:,
                          source_text: 'The library first opened its doors to readers in 1923.')
                     .verdict
    end

    it 'returns the judged verdict with quote and explanation' do
      expect(verdict.verdict).to eq('supported')
      expect(verdict.quote).to eq('first opened its doors to readers in 1923')
      expect(verdict.explanation).to be_present
    end

    it 'passes through model and usage for cost tracking' do
      expect(verdict.model).to eq('claude-opus-4-8')
      expect(verdict.usage).to eq(input_tokens: 200, output_tokens: 40)
    end

    it 'sends the claim, its context, and the source text to the judge' do
      verdict
      expect(prompts.first[:user]).to include('The library opened in 1923.')
      expect(prompts.first[:user]).to include('on Main Street')
      expect(prompts.first[:user]).to include('opened its doors')
      expect(prompts.first[:json_schema]).to eq(described_class::JUDGE_SCHEMA)
    end

    it 'does not flag truncation for a short source' do
      expect(verdict.source_truncated).to eq(false)
    end
  end

  context 'with a source longer than the size cap' do
    let(:adapter) { instance_double(Llm::AnthropicAdapter) }
    let(:cap) { described_class::SOURCE_TEXT_CHARACTER_LIMIT }
    let(:long_source) { "The library opened in 1923. #{'x' * cap}" }

    before do
      allow(Llm::Client).to receive(:adapter).and_return(adapter)
      allow(adapter).to receive(:complete) do |user:, **_rest|
        expect(user.length).to be < described_class::SOURCE_TEXT_CHARACTER_LIMIT + 1000
        json = { 'verdict' => 'supported', 'quote' => 'q', 'explanation' => 'e' }
        Llm::Response.new(text: json.to_json, json:, model: 'm', usage: {})
      end
    end

    it 'truncates the source and records the flag' do
      verdict = described_class.new(claim:, source_text: long_source).verdict
      expect(verdict.source_truncated).to eq(true)
    end
  end

  context 'when the source was not fetched' do
    it 'short-circuits to source_inaccessible without an LLM call' do
      expect(Llm::Client).not_to receive(:adapter)
      verdict = described_class.new(claim:, source_text: nil,
                                    source_status: :inaccessible).verdict
      expect(verdict.verdict).to eq('source_inaccessible')
      expect(verdict.explanation).to include('inaccessible')
    end

    it 'treats offline sources the same way' do
      verdict = described_class.new(claim:, source_text: nil,
                                    source_status: :offline_source).verdict
      expect(verdict.verdict).to eq('source_inaccessible')
    end
  end

  context 'with a plain string claim (eval harness usage)' do
    let(:adapter) { instance_double(Llm::AnthropicAdapter) }

    before do
      allow(Llm::Client).to receive(:adapter).and_return(adapter)
      json = { 'verdict' => 'not_supported', 'quote' => '', 'explanation' => 'e' }
      allow(adapter).to receive(:complete)
        .and_return(Llm::Response.new(text: json.to_json, json:, model: 'm', usage: {}))
    end

    it 'accepts a string claim' do
      verdict = described_class.new(claim: 'The mayor founded three companies.',
                                    source_text: 'The mayor was a teacher.').verdict
      expect(verdict.verdict).to eq('not_supported')
    end
  end
end
