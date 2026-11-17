# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/pangram_api"

describe PangramApi do
  let(:text) { 'Some prose to classify.' }
  # Response shape recorded from the live API on 2026-09-03, with the text fields removed.
  let(:v4_result) do
    { 'stage' => 'STAGE_SUCCESS',
      'version' => '4.0',
      'prediction' => 'We believe that this entire text is AI.',
      'prediction_short' => 'AI',
      'fraction_ai' => 1.0, 'fraction_ai_assisted' => 0.0, 'fraction_human' => 0.0,
      'headline' => 'AI Generated',
      'num_ai_segments' => 1, 'num_ai_assisted_segments' => 0, 'num_human_segments' => 0,
      'windows' => [{ 'label' => 'AI-Generated', 'ai_assistance_score' => 0.9999960660934448,
                      'confidence' => 'High', 'start_index' => 0, 'end_index' => 2281,
                      'word_count' => 313, 'token_length' => 392,
                      'is_humanized' => false, 'humanizer_score' => 0.004439877346158028 }],
      'dashboard_link' => 'https://www.pangram.com/history/8b8e9ea2' }
  end
  let(:task_id) { 'cc1ff841-8a0c-412c-add8-e77bd459b6eb' }
  let(:task_url) { "#{PangramApi::V4_API_URL}/#{task_id}" }

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('pangram_api_key').and_return('test-key')
    stub_const('PangramApi::POLL_INTERVAL', 0)
  end

  describe '.v4' do
    def stub_task_submission
      stub_request(:post, PangramApi::V4_API_URL)
        .with(body: { public_dashboard_link: true, model: 'pangram-4', text: },
              headers: { 'x-api-key' => 'test-key' })
        .to_return(status: 200, body: { task_id: }.to_json)
    end

    it 'submits a task and polls until it succeeds' do
      submission = stub_task_submission
      polling = stub_request(:get, task_url)
                .with(headers: { 'x-api-key' => 'test-key' })
                .to_return({ status: 200, body: { stage: 'STAGE_RUNNING' }.to_json },
                           { status: 200, body: v4_result.to_json })

      api = described_class.v4
      result = api.inference(text)

      expect(submission).to have_been_requested
      expect(polling).to have_been_requested.twice
      expect(result).to eq(v4_result)
      expect(api.result).to eq(v4_result)
    end

    it 'raises TaskFailed when the task reaches the failure stage' do
      stub_task_submission
      stub_request(:get, task_url)
        .to_return(status: 200, body: { stage: 'STAGE_FAILED', error: 'boom' }.to_json)

      expect { described_class.v4.inference(text) }
        .to raise_error(PangramApi::TaskFailed, /#{task_id}.*boom/)
    end

    it 'raises TaskTimeout when the task does not finish in time' do
      stub_const('PangramApi::TASK_TIMEOUT', 0)
      stub_task_submission
      stub_request(:get, task_url).to_return(status: 200, body: { stage: 'STAGE_RUNNING' }.to_json)

      expect { described_class.v4.inference(text) }.to raise_error(PangramApi::TaskTimeout)
    end

    it 'raises RequestError when the submission is rejected' do
      stub_request(:post, PangramApi::V4_API_URL)
        .to_return(status: 402, body: { error: 'insufficient credits' }.to_json)

      expect { described_class.v4.inference(text) }.to raise_error(PangramApi::RequestError) do |e|
        expect(e.status).to eq(402)
      end
    end

    it 'accepts a result from the pinned version' do
      stub_task_submission
      stub_request(:get, task_url).to_return(status: 200, body: v4_result.to_json)

      expect(described_class.v4(expected_version: '4.0').inference(text)).to eq(v4_result)
    end

    it 'raises ModelMismatch when the API answers as a different version than pinned' do
      stub_task_submission
      stub_request(:get, task_url)
        .to_return(status: 200, body: v4_result.merge('version' => '4.2').to_json)

      expect { described_class.v4(expected_version: '4.1').inference(text) }
        .to raise_error(PangramApi::ModelMismatch, /expected Pangram 4.1.*"4.2"/)
    end

    it 'raises RequestError when a status check fails' do
      stub_task_submission
      stub_request(:get, task_url).to_return(status: 500, body: 'Internal Server Error')

      expect { described_class.v4.inference(text) }.to raise_error(PangramApi::RequestError) do |e|
        expect(e.status).to eq(500)
      end
    end
  end
end
