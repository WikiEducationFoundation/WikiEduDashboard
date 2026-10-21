# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/originality_api"

describe OriginalityApi do
  let(:text) { (['Enough words to clear the minimum length.'] * 10).join(' ') }
  # Shape recorded from the live API on 2026-09-03, with the text fields shortened.
  let(:classic_result) do
    { 'results' => {
      'properties' => { 'id' => 'x3vze1buqfni7ogk', 'title' => 'API Scan',
                        'publicLink' => 'https://app.originality.ai/share/x3vze1buqfni7ogk',
                        'content' => text, 'formattedContent' => text },
      'credits' => { 'used' => 1 },
      'ai' => { 'aiModel' => 'turbo',
                'classification' => { 'AI' => 1, 'Original' => 0 },
                'confidence' => { 'AI' => 0.9989, 'Original' => 0.0011 },
                'blocks' => [{ 'text' => 'first block',
                               'result' => { 'fake' => 0.9994, 'real' => 0.0006,
                                             'status' => 'success' } }] },
      'plagiarism' => { 'error' => 'not selected' },
      'aiAllowance' => { 'error' => 'not selected' }
    } }
  end
  let(:allowance_result) do
    classic_result.deep_merge(
      'results' => {
        'credits' => { 'used' => 2 },
        'ai' => { 'aiModel' => 'allowance-40%' },
        'aiAllowance' => { '40' => { 'confidence' => { 'AI' => 0.0299, 'Original' => 0.9701 },
                                     'blocks' => [{ 'text' => 'first block',
                                                    'result' => { 'fake' => 0.448 } }] } }
      }
    ).tap { |result| result['results']['aiAllowance'].delete('error') }
  end

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('originality_api_key').and_return('test-key')
  end

  describe 'classic models' do
    it 'posts the text with the model version and returns the parsed result' do
      stub = stub_request(:post, OriginalityApi::API_URL)
             .with(body: hash_including('aiModelVersion' => 'turbo', 'check_ai' => true,
                                        'content' => text),
                   headers: { 'X-OAI-API-KEY' => 'test-key' })
             .to_return(status: 200, body: classic_result.to_json)

      api = described_class.turbo
      result = api.inference(text)

      expect(stub).to have_been_requested
      expect(result).to eq(classic_result)
      expect(api.result).to eq(classic_result)
    end

    it 'does not request an AI allowance check' do
      stub = stub_request(:post, OriginalityApi::API_URL)
             .with { |req| !JSON.parse(req.body).key?('check_ai_allowance') }
             .to_return(status: 200, body: classic_result.to_json)

      described_class.turbo.inference(text)

      expect(stub).to have_been_requested
    end

    it 'exposes the current classic model identifiers' do
      expect(described_class.lite_102.expected_model).to eq('lite-102')
      expect(described_class.academic.expected_model).to eq('academic')
    end
  end

  describe '.ai_allowance' do
    it 'requests the allowance check at the given threshold instead of a model version' do
      stub = stub_request(:post, OriginalityApi::API_URL)
             .with { |req| body = JSON.parse(req.body)
                           body['check_ai_allowance'] == true &&
                             body['ai_allowance_threshold'] == 40 &&
                             body['check_ai'] == true &&
                             !body.key?('aiModelVersion') }
             .to_return(status: 200, body: allowance_result.to_json)

      result = described_class.ai_allowance(threshold: 40).inference(text)

      expect(stub).to have_been_requested
      expect(result['results']['aiAllowance']['40']['confidence']['AI']).to eq(0.0299)
    end

    it 'rejects thresholds Originality does not offer' do
      expect { described_class.ai_allowance(threshold: 30) }.to raise_error(ArgumentError)
    end
  end

  describe 'error handling' do
    it 'refuses to send fewer than 50 words' do
      expect { described_class.turbo.inference('too short') }
        .to raise_error(OriginalityApi::TextTooShort)
      expect(a_request(:post, OriginalityApi::API_URL)).not_to have_been_made
    end

    it 'raises RequestError with the status on a non-success response' do
      stub_request(:post, OriginalityApi::API_URL)
        .to_return(status: 401, body: { error: 'Invalid API Key' }.to_json)

      expect { described_class.turbo.inference(text) }
        .to raise_error(OriginalityApi::RequestError) do |e|
          expect(e.status).to eq(401)
          expect(e.message).to include('Invalid API Key')
        end
    end

    it 'raises RequestError when a 200 carries an error payload' do
      stub_request(:post, OriginalityApi::API_URL)
        .to_return(status: 200, body: { error: true, message: 'A minimum of 50 words' }.to_json)

      expect { described_class.turbo.inference(text) }
        .to raise_error(OriginalityApi::RequestError, /minimum of 50 words/)
    end

    it 'raises ModelMismatch when the API silently ran a different model' do
      fallback = classic_result.deep_merge('results' => { 'ai' => { 'aiModel' => 'lite-102' } })
      stub_request(:post, OriginalityApi::API_URL).to_return(status: 200, body: fallback.to_json)

      expect { described_class.turbo.inference(text) }
        .to raise_error(OriginalityApi::ModelMismatch, /requested turbo.*lite-102/)
    end

    it 'raises ModelMismatch when an allowance scan comes back as a classic model' do
      stub_request(:post, OriginalityApi::API_URL)
        .to_return(status: 200, body: classic_result.to_json)

      expect { described_class.ai_allowance(threshold: 15).inference(text) }
        .to raise_error(OriginalityApi::ModelMismatch, /allowance-15%/)
    end
  end

  describe '.credit_balance' do
    it 'returns the remaining credits' do
      stub_request(:get, OriginalityApi::CREDIT_BALANCE_URL)
        .with(headers: { 'X-OAI-API-KEY' => 'test-key' })
        .to_return(status: 200, body: { balance: 14_488, subscription: 0 }.to_json)

      expect(described_class.credit_balance).to eq(14_488)
    end

    it 'raises RequestError when the balance request fails' do
      stub_request(:get, OriginalityApi::CREDIT_BALANCE_URL).to_return(status: 403, body: 'nope')

      expect { described_class.credit_balance }.to raise_error(OriginalityApi::RequestError)
    end
  end
end
