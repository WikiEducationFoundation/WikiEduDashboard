# frozen_string_literal: true

# Receives the inbound email Mailgun forwards to /email_processor, which
# Griddler turns into tickets (see lib/email_processor.rb). Mailgun signs each
# post with the account's webhook signing key; without checking it, anyone
# could post a forged email and open a ticket as any sender.
#
# With no key configured, every post is refused. P&E receives no email, and a
# server without the key can't tell Mailgun from a forger. Mailgun retries a
# refused post for several hours, so mail that arrives while the key is being
# set up is not lost.
class InboundEmailsController < Griddler::EmailsController
  before_action :verify_mailgun_signature

  private

  def verify_mailgun_signature
    key = ENV['mailgun_webhook_signing_key']
    return if key.present? && signature_matches?(key)
    head :unauthorized
  end

  def signature_matches?(key)
    timestamp, token, signature = params.values_at(:timestamp, :token, :signature)
    return false if [timestamp, token, signature].any?(&:blank?)
    expected = OpenSSL::HMAC.hexdigest('SHA256', key, "#{timestamp}#{token}")
    ActiveSupport::SecurityUtils.secure_compare(expected, signature.to_s)
  end
end
