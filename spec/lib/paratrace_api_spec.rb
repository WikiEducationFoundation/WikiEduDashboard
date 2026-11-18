# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/paratrace_api"

describe ParatraceApi do
  let(:text) { 'Some prose to classify.' }
  let(:detect_url) { "#{ParatraceApi::API_URL}/detect" }
  # Shape recorded from the live API on 2026-11-18.
  let(:result) do
    { 'detector_version' => 'v10-ft-g',
      'documents' => [{ 'document' => 'text', 'probability' => 0.00016, 'is_ai' => false,
                        'verdict' => 'human', 'ai_fraction' => 0.0, 'category' => 'human',
                        'confidence' => 'high', 'operating_point' => 'strict',
                        'threshold' => 0.1698, 'n_words' => 150, 'n_tokens' => 178,
                        'n_windows' => 1, 'warnings' => [],
                        'windows' => [{ 'start' => 0, 'end' => 1003, 'probability' => 0.00016,
                                        'band' => 'human' }],
                        'segments' => [{ 'start' => 0, 'end' => 1003, 'label' => 'human',
                                         'probability' => 0.00016, 'band' => 'human' }],
                        'credits' => 1 }],
      'credits_charged' => 1, 'credits_remaining' => 999 }
  end

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('paratrace_api_key').and_return('pt_test')
  end

  it 'posts the text at the strict operating point and returns the parsed result' do
    stub = stub_request(:post, detect_url)
           .with(body: { text:, operating_point: 'strict' }.to_json,
                 headers: { 'Authorization' => 'Bearer pt_test' })
           .to_return(status: 200, body: result.to_json)

    api = described_class.v10
    expect(api.inference(text)).to eq(result)
    expect(api.result).to eq(result)
    expect(stub).to have_been_requested
  end

  it 'raises ModelMismatch when the API answers as another detector version' do
    stub_request(:post, detect_url)
      .to_return(status: 200, body: result.merge('detector_version' => 'v11').to_json)

    expect { described_class.v10.inference(text) }
      .to raise_error(ParatraceApi::ModelMismatch, /expected ParaTrace v10-ft-g.*"v11"/)
  end

  it 'raises RequestError with the status and detail on a refusal' do
    stub_request(:post, detect_url)
      .to_return(status: 422, body: { detail: 'text is empty' }.to_json)

    expect { described_class.v10.inference('') }.to raise_error(ParatraceApi::RequestError) do |e|
      expect(e.status).to eq(422)
      expect(e.message).to include('text is empty')
    end
  end

  it 'reads the remaining credits from the account endpoint' do
    stub_request(:get, "#{ParatraceApi::API_URL}/account")
      .with(headers: { 'Authorization' => 'Bearer pt_test' })
      .to_return(status: 200, body: { credits_total: 1000, credits_used: 1,
                                      credits_remaining: 999, tokens_per_credit: 512 }.to_json)

    expect(described_class.credit_balance).to eq(999)
  end
end
