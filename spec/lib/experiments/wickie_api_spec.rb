# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/experiments/wickie_api"

describe WickieApi do
  let(:username) { 'Jane Doe' }
  let(:course_slug) { 'University_of_X/Course_Name_(Fall_2026)' }
  let(:enroll) { described_class.new.enroll(username:, course_slug:) }

  def stub_secret(value)
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('wickie_enroll_secret').and_return(value)
  end

  context 'when the enrollment secret is configured' do
    before { stub_secret 'a-real-secret' }

    it 'posts the enrollment payload to the data collection server' do
      stub = stub_request(:post, WickieApi::ENROLL_URL)
             .with(body: { secret: 'a-real-secret', username:, course: course_slug },
                   headers: { 'Content-Type' => 'application/json' })
             .to_return(status: 200, body: '{"enrolled": true}')
      enroll
      expect(stub).to have_been_requested
    end

    it 'reports a rejected enrollment to Sentry without raising' do
      stub_request(:post, WickieApi::ENROLL_URL).to_return(status: 401, body: 'bad secret')
      expect(Sentry).to receive(:capture_message)
      expect { enroll }.not_to raise_error
    end

    it 'raises on a server error, so Sidekiq will retry' do
      stub_request(:post, WickieApi::ENROLL_URL).to_return(status: 503)
      expect { enroll }.to raise_error(WickieApi::EnrollmentFailed)
    end

    it 'lets a connection failure propagate, so Sidekiq will retry' do
      stub_request(:post, WickieApi::ENROLL_URL).to_raise(Faraday::ConnectionFailed)
      expect { enroll }.to raise_error(Faraday::ConnectionFailed)
    end
  end

  context 'when no enrollment secret is configured' do
    before { stub_secret nil }

    it 'makes no request at all' do
      stub = stub_request(:post, WickieApi::ENROLL_URL)
      enroll
      expect(stub).not_to have_been_requested
    end
  end
end
