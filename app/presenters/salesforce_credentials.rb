# frozen_string_literal: true

#= Presenter for Setting / Salesforce
class SalesforceCredentials
  def self.setting
    Setting.find_or_create_by(key: 'salesforce')
  end

  def self.get
    setting.value
  end

  def self.update(password, token)
    setting.update(value: { password:, security_token: token })
  end
end
