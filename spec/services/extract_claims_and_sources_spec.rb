# frozen_string_literal: true

require 'rails_helper'

describe ExtractClaimsAndSources do
  let(:html) do
    File.read("#{Rails.root}/fixtures/claim_verification_eval/third_place_diff.html")
  end

  context 'in structural mode (default)' do
    let(:service) { described_class.new(html) }

    it 'returns one claim per cited sentence' do
      expect(service.claims.length).to eq(2)
      expect(service.claims.first.ref_ids).to eq(['cite_note-1'])
    end

    it 'returns the citations' do
      expect(service.citations.map(&:ref_id)).to eq(%w[cite_note-1 cite_note-2])
    end

    it 'makes no LLM calls' do
      expect(Llm::Client).not_to receive(:adapter)
      expect(service.usage).to be_empty
    end
  end

  context 'in llm mode' do
    let(:adapter) { instance_double(Llm::AnthropicAdapter) }
    let(:usage) { { input_tokens: 100, output_tokens: 50 } }

    before do
      allow(Llm::Client).to receive(:adapter).and_return(adapter)
      allow(adapter).to receive(:complete) do |user:, **_rest|
        json = { 'claims' => ["First atomic fact from: #{user[0, 20]}", 'Second atomic fact'] }
        Llm::Response.new(text: json.to_json, json:, model: 'claude-opus-4-8', usage:)
      end
    end

    let(:service) { described_class.new(html, mode: :llm) }

    it 'decomposes each cited sentence into atomic claims' do
      expect(service.claims.length).to eq(4)
      expect(service.claims.map(&:sentence)).to include('Second atomic fact')
    end

    it 'keeps each atomic claim linked to the original citations' do
      expect(service.claims.map(&:ref_ids).uniq).to contain_exactly(
        ['cite_note-1'], ['cite_note-2']
      )
    end

    it 'collects usage for cost tracking' do
      expect(service.usage).to eq([usage, usage])
    end
  end
end
