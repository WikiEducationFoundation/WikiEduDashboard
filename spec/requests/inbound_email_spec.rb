# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/email_processor"

# Mailgun forwards inbound email to /email_processor and signs each post with
# the webhook signing key. Unsigned or wrongly signed posts are forgeries.
describe 'Inbound email', type: :request do
  let(:signing_key) { 'test-signing-key' }
  let(:timestamp) { Time.now.to_i.to_s }
  let(:token) { 'a' * 50 }
  let(:email_params) do
    { 'recipient' => 'staff@wikiedu.org', 'sender' => 'student@example.edu',
      'from' => 'Student <student@example.edu>', 'subject' => 'Help',
      'body-plain' => 'Please help.', 'To' => 'staff@wikiedu.org' }
  end

  def signature_for(key)
    OpenSSL::HMAC.hexdigest('SHA256', key, "#{timestamp}#{token}")
  end

  def post_email(signature)
    post '/email_processor',
         params: email_params.merge('timestamp' => timestamp, 'token' => token,
                                    'signature' => signature)
  end

  context 'when the signing key is configured' do
    before do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('mailgun_webhook_signing_key').and_return(signing_key)
    end

    it 'processes an email Mailgun signed' do
      expect_any_instance_of(EmailProcessor).to receive(:process)
      post_email(signature_for(signing_key))
      expect(response.status).to eq(200)
    end

    it 'refuses an email signed with another key' do
      expect_any_instance_of(EmailProcessor).not_to receive(:process)
      post_email(signature_for('some-other-key'))
      expect(response.status).to eq(401)
    end

    it 'refuses a signed email whose timestamp is old' do
      expect_any_instance_of(EmailProcessor).not_to receive(:process)
      old = 1.hour.ago.to_i.to_s
      post '/email_processor',
           params: email_params.merge('timestamp' => old, 'token' => token,
                                      'signature' => OpenSSL::HMAC.hexdigest('SHA256', signing_key,
                                                                             "#{old}#{token}"))
      expect(response.status).to eq(401)
    end

    it 'refuses a second email with a token already used' do
      allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::MemoryStore.new)
      allow_any_instance_of(EmailProcessor).to receive(:process)
      post_email(signature_for(signing_key))
      expect(response.status).to eq(200)
      post_email(signature_for(signing_key))
      expect(response.status).to eq(401)
    end

    it 'refuses an unsigned email' do
      expect_any_instance_of(EmailProcessor).not_to receive(:process)
      post '/email_processor', params: email_params
      expect(response.status).to eq(401)
    end
  end

  # P&E receives no email, and a server without the key can't tell Mailgun
  # from a forger.
  context 'when no signing key is configured' do
    it 'refuses every email' do
      expect_any_instance_of(EmailProcessor).not_to receive(:process)
      post_email(signature_for(signing_key))
      expect(response.status).to eq(401)
    end
  end
end
