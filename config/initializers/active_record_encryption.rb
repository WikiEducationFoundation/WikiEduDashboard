# frozen_string_literal: true

# ActiveRecord encryption keys, used by LtiConsumerKey#secret (the LTI 1.1
# shared secrets the Dashboard issues). Figaro puts config/application.yml into
# ENV, so the three keys live there alongside the other secrets.
#
# Configured through `ActiveRecord::Encryption.configure` rather than
# `config.active_record.encryption.*`: by the time an initializer runs, the
# framework has already consumed the latter, and the keys never take effect.
#
# Outside production, fall back to fixed non-secret values so a developer whose
# application.yml predates this feature, and CI, can still run the suite. In
# production nothing is configured when the keys are absent: encrypting then
# raises where it is used, which breaks only the LTI 1.1 credential feature
# rather than booting the whole app with a publicly known key.
DEVELOPMENT_ENCRYPTION_KEYS = {
  primary_key: 'development_only_primary_key_not_a_secret',
  deterministic_key: 'development_only_deterministic_key_x',
  key_derivation_salt: 'development_only_derivation_salt_xx'
}.freeze

keys = {
  primary_key: ENV.fetch('active_record_encryption_primary_key', nil),
  deterministic_key: ENV.fetch('active_record_encryption_deterministic_key', nil),
  key_derivation_salt: ENV.fetch('active_record_encryption_key_derivation_salt', nil)
}

keys = DEVELOPMENT_ENCRYPTION_KEYS if keys.values.any?(&:blank?) && !Rails.env.production?

ActiveSupport.on_load(:active_record) do
  ActiveRecord::Encryption.configure(**keys) if keys.values.all?(&:present?)
end
