# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/llm/client"

describe Llm::Client do
  it 'returns the anthropic adapter by default' do
    expect(described_class.adapter).to be_an(Llm::AnthropicAdapter)
  end

  it 'raises for an unknown provider' do
    expect { described_class.adapter('mystery') }
      .to raise_error(Llm::Client::UnknownProviderError, /mystery/)
  end
end

describe Llm::AnthropicAdapter do
  let(:adapter) { described_class.new(max_retries: 0) }
  let(:messages_url) { %r{\Ahttps://api\.anthropic\.com/v1/messages} }
  let(:system_blocks) {
 [{ text: 'Instructions.', cache: false }, { text: 'Article.', cache: true }] }
  let(:schema) do
    { type: 'object', properties: { verdict: { type: 'string' } },
      required: ['verdict'], additionalProperties: false }
  end
  let(:stop_reason) { 'end_turn' }
  let(:response_text) { '{"verdict":"supported"}' }
  let(:api_response) do
    {
      id: 'msg_test', type: 'message', role: 'assistant', model: 'claude-opus-5-5',
      content: [{ type: 'text', text: response_text }],
      stop_reason:, stop_details: nil,
      usage: { input_tokens: 25, output_tokens: 8, cache_read_input_tokens: 100,
               cache_creation_input_tokens: 0 }
    }
  end

  def stub_messages(status: 200, body: api_response)
    stub_request(:post, messages_url)
      .to_return(status:, body: body.to_json, headers: { 'Content-Type' => 'application/json' })
  end

  def complete
    adapter.complete(system_blocks:, user: 'Check this.', json_schema: schema,
                     model: 'claude-opus-5-5', effort: 'medium')
  end

  def request_body
    body = nil
    expect(WebMock).to(have_requested(:post, messages_url).with { |req|
 body = JSON.parse(req.body) })
    body
  end

  context 'with a successful structured completion' do
    before { stub_messages }

    it 'returns parsed JSON, the model and usage including cache reads' do
      response = complete
      expect(response.json).to eq('verdict' => 'supported')
      expect(response.model).to eq('claude-opus-5-5')
      expect(response.usage).to include('input_tokens' => 25, 'output_tokens' => 8,
                                        'cache_read_input_tokens' => 100,
                                        'message_id' => 'msg_test')
    end

    it 'sends system blocks with a cache breakpoint on the cached one' do
      complete
      system = request_body['system']
      expect(system.map { |block| block['text'] }).to eq(%w[Instructions. Article.])
      expect(system.first).not_to have_key('cache_control')
      expect(system.last['cache_control']).to eq('type' => 'ephemeral')
    end

    it 'requests structured output and effort via output_config' do
      complete
      output_config = request_body['output_config']
      expect(output_config['effort']).to eq('medium')
      expect(output_config.dig('format', 'type')).to eq('json_schema')
      expect(output_config.dig('format', 'schema', 'required')).to eq(['verdict'])
    end

    it 'opts into the server-side refusal fallback' do
      complete
      expect(request_body['fallbacks']).to eq('default')
      expect(WebMock).to have_requested(:post, messages_url)
        .with(headers: { 'anthropic-beta' => /server-side-fallback-2026-07-01/ })
    end
  end

  context 'when the model refuses' do
    before do
      stub_messages(body: api_response.merge(
        stop_reason: 'refusal',
        stop_details: { type: 'refusal', category: nil, explanation: 'declined' }
      ))
    end

    it 'raises a RefusalError' do
      expect { complete }.to raise_error(Llm::RefusalError, /declined/)
    end
  end

  context 'when the output is truncated' do
    let(:stop_reason) { 'max_tokens' }

    before { stub_messages }

    it 'raises an IncompleteResponseError' do
      expect { complete }.to raise_error(Llm::IncompleteResponseError, /max_tokens/)
    end
  end

  context 'when the structured output is not JSON' do
    let(:response_text) { 'not json' }

    before { stub_messages }

    it 'raises an IncompleteResponseError' do
      expect { complete }.to raise_error(Llm::IncompleteResponseError, /JSON/)
    end
  end

  context 'when rate limited' do
    before do
      error = { type: 'rate_limit_error', message: 'slow down' }
      stub_messages(status: 429, body: { type: 'error', error: })
    end

    it 'raises a RetryableError' do
      expect { complete }.to raise_error(Llm::RetryableError)
    end
  end

  context 'when overloaded' do
    before do
      stub_messages(status: 529, body: { type: 'error',
                                         error: { type: 'overloaded_error', message: 'busy' } })
    end

    it 'raises a RetryableError' do
      expect { complete }.to raise_error(Llm::RetryableError)
    end
  end

  context 'when the request is invalid' do
    before do
      stub_messages(status: 400, body: { type: 'error',
                                         error: { type: 'invalid_request_error', message: 'bad' } })
    end

    it 'raises a RequestError' do
      expect { complete }.to raise_error(Llm::RequestError, /400/)
    end
  end
end
