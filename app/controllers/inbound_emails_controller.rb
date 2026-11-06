# frozen_string_literal: true

# Receives the inbound email Mailgun forwards to /email_processor, which
# Griddler turns into tickets (see lib/email_processor.rb). Mailgun signs each
# post with the account's webhook signing key; without checking it, anyone
# could post a forged email and open a ticket as any sender.
#
# With no key configured, every post is refused. P&E receives no email, and a
# server without the key can't tell Mailgun from a forger.
class InboundEmailsController < Griddler::EmailsController
  before_action :verify_mailgun_signature
  after_action :remember_token

  # Mailgun's signature covers only the timestamp and token, not the email,
  # so a signature seen once (in a log, say) could carry any email. Old
  # timestamps and tokens already used are refused too, as Mailgun advises.
  MAX_AGE = 15.minutes

  private

  def verify_mailgun_signature
    key = ENV['mailgun_webhook_signing_key']
    return if key.present? && signature_matches?(key) && fresh? && !token_used?
    head :unauthorized
  end

  def fresh?
    (Time.zone.now.to_i - params[:timestamp].to_i).abs <= MAX_AGE
  end

  # Recorded only once an email is processed, so a delivery that failed can
  # still be retried with the same token.
  def token_used?
    Rails.cache.exist?(token_cache_key)
  end

  def remember_token
    return unless response.successful?
    Rails.cache.write(token_cache_key, true, expires_in: MAX_AGE * 2)
  end

  def token_cache_key
    "mailgun-token-#{params[:token]}"
  end

  def signature_matches?(key)
    timestamp, token, signature = params.values_at(:timestamp, :token, :signature)
    return false if [timestamp, token, signature].any?(&:blank?)
    expected = OpenSSL::HMAC.hexdigest('SHA256', key, "#{timestamp}#{token}")
    ActiveSupport::SecurityUtils.secure_compare(expected, signature.to_s)
  end
end
