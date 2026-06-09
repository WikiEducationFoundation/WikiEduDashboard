# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/llm/client"

describe Llm::Client do
  describe '.adapter' do
    it 'returns the anthropic adapter by default' do
      expect(described_class.adapter).to be_an(Llm::AnthropicAdapter)
    end

    it 'raises for an unknown provider' do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('llm_provider').and_return('mystery')
      expect { described_class.adapter }
        .to raise_error(Llm::Client::UnknownProviderError, /mystery/)
    end
  end
end

describe Llm::AnthropicAdapter do
  let(:api_response) do
    {
      id: 'msg_test', type: 'message', role: 'assistant',
      model: 'claude-opus-4-8',
      content: [{ type: 'text', text: response_text }],
      stop_reason: 'end_turn',
      usage: { input_tokens: 25, output_tokens: 8 }
    }
  end

  before do
    stub_request(:post, 'https://api.anthropic.com/v1/messages')
      .to_return(status: 200, body: api_response.to_json,
                 headers: { 'Content-Type' => 'application/json' })
  end

  context 'with a plain text completion' do
    let(:response_text) { 'Paris.' }

    it 'returns a normalized response' do
      response = described_class.new.complete(system: 'Answer briefly.',
                                              user: 'Capital of France?')
      expect(response.text).to eq('Paris.')
      expect(response.json).to be_nil
      expect(response.model).to eq('claude-opus-4-8')
      expect(response.usage).to eq(input_tokens: 25, output_tokens: 8)
    end

    it 'sends the system prompt and user message' do
      described_class.new.complete(system: 'Answer briefly.', user: 'Capital of France?')
      expect(WebMock).to have_requested(:post, 'https://api.anthropic.com/v1/messages')
        .with { |req| JSON.parse(req.body).values_at('system', 'max_tokens') ==
                      ['Answer briefly.', 16_000] }
    end
  end

  context 'with a json_schema' do
    let(:response_text) { '{"verdict":"supported"}' }
    let(:schema) do
      { type: 'object', properties: { verdict: { type: 'string' } },
        required: ['verdict'], additionalProperties: false }
    end

    it 'parses the structured output' do
      response = described_class.new.complete(system: 'Judge.', user: 'claim...',
                                              json_schema: schema)
      expect(response.json).to eq('verdict' => 'supported')
    end

    it 'requests structured output via output_config' do
      described_class.new.complete(system: 'Judge.', user: 'claim...', json_schema: schema)
      expect(WebMock).to have_requested(:post, 'https://api.anthropic.com/v1/messages')
        .with { |req| JSON.parse(req.body).dig('output_config', 'format', 'type') == 'json_schema' }
    end
  end

  context 'with llm_model set' do
    let(:response_text) { 'ok' }

    it 'uses the configured model' do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('llm_model').and_return('claude-haiku-4-5')
      described_class.new.complete(system: 's', user: 'u')
      expect(WebMock).to have_requested(:post, 'https://api.anthropic.com/v1/messages')
        .with { |req| JSON.parse(req.body)['model'] == 'claude-haiku-4-5' }
    end
  end
end
