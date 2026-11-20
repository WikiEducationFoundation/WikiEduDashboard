# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/originality_api"

describe OriginalityApi do
  let(:text) { (['Enough words to clear the minimum length.'] * 10).join(' ') }
  # Shape recorded from the live API on 2026-11-17, with the text fields shortened.
  let(:model_5_result) do
    { 'results' => {
      'properties' => { 'id' => 't6i9x3cn8zwrs7p4', 'title' => 'Wiki Education Dashboard',
                        'publicLink' => 'https://app.originality.ai/share/t6i9x3cn8zwrs7p4',
                        'content' => text, 'formattedContent' => text },
      'credits' => { 'used' => 4 },
      'ai' => { 'model' => 'model-5.0', 'prediction_label' => 'mixed',
                'ai_assisted_percent' => 60,
                'sentences' => [{ 'start_index' => 0, 'end_index' => 232, 'text' => 'first',
                                  'ai_score' => 0.303 },
                                { 'start_index' => 232, 'end_index' => 400, 'text' => 'second',
                                  'ai_score' => 1 }] },
      'plagiarism' => { 'error' => 'not selected' },
      'aiAllowance' => { 'error' => 'not selected' }
    } }
  end

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('originality_api_key').and_return('test-key')
  end

  describe '5.0 models' do
    it 'posts the text with the model version and a title, and returns the parsed result' do
      stub = stub_request(:post, OriginalityApi::API_URL)
             .with(body: hash_including('aiModelVersion' => 'model-5.0', 'check_ai' => true,
                                        'title' => 'Wiki Education Dashboard',
                                        'content' => text),
                   headers: { 'X-OAI-API-KEY' => 'test-key' })
             .to_return(status: 200, body: model_5_result.to_json)

      api = described_class.model_5
      result = api.inference(text)

      expect(stub).to have_been_requested
      expect(result).to eq(model_5_result)
      expect(api.result).to eq(model_5_result)
    end

    it 'selects 5.0 Max by its own identifier' do
      max_result = model_5_result.deep_merge(
        'results' => { 'ai' => { 'model' => 'model-5.0-max' } }
      )
      stub = stub_request(:post, OriginalityApi::API_URL)
             .with(body: hash_including('aiModelVersion' => 'model-5.0-max'))
             .to_return(status: 200, body: max_result.to_json)

      described_class.model_5_max.inference(text)

      expect(stub).to have_been_requested
      expect(described_class.model_5_max.expected_model).to eq('model-5.0-max')
    end
  end

  describe 'error handling' do
    it 'refuses to send fewer than 50 words' do
      expect { described_class.model_5.inference('too short') }
        .to raise_error(OriginalityApi::TextTooShort)
      expect(a_request(:post, OriginalityApi::API_URL)).not_to have_been_made
    end

    it 'raises RequestError with the status on a non-success response' do
      stub_request(:post, OriginalityApi::API_URL)
        .to_return(status: 401, body: { error: 'Invalid API Key' }.to_json)

      expect { described_class.model_5.inference(text) }
        .to raise_error(OriginalityApi::RequestError) do |e|
          expect(e.status).to eq(401)
          expect(e.message).to include('Invalid API Key')
        end
    end

    it 'raises RequestError when a 200 carries an error payload' do
      stub_request(:post, OriginalityApi::API_URL)
        .to_return(status: 200, body: { error: true, message: 'A minimum of 50 words' }.to_json)

      expect { described_class.model_5.inference(text) }
        .to raise_error(OriginalityApi::RequestError, /minimum of 50 words/)
    end

    it 'treats a result without a model as a failed call, not a model change' do
      broken = model_5_result.deep_merge('results' => { 'ai' => { 'error' => 'scan failed' } })
      broken['results']['ai'].delete('model')
      stub_request(:post, OriginalityApi::API_URL).to_return(status: 200, body: broken.to_json)

      expect { described_class.model_5.inference(text) }
        .to raise_error(OriginalityApi::RequestError, /HTTP 200/)
    end

    it 'raises ModelMismatch when the API silently ran a different model' do
      fallback = model_5_result.deep_merge('results' => { 'ai' => { 'model' => 'model-5.0' } })
      stub_request(:post, OriginalityApi::API_URL).to_return(status: 200, body: fallback.to_json)

      expect { described_class.model_5_max.inference(text) }
        .to raise_error(OriginalityApi::ModelMismatch, /requested model-5.0-max.*"model-5.0"/)
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
