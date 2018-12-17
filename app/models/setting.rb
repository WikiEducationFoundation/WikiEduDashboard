# frozen_string_literal: true
# == Schema Information
#
# Table name: settings
#
#  id         :bigint(8)        not null, primary key
#  key        :string(255)
#  value      :text(65535)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

#= Generic store of global settings, with a key mapping to a hash of associated data.
class Setting < ApplicationRecord
  serialize :value, Hash
  def self.set_hash(property, key, value)
    setting = find_or_create_by(key: property)
    setting.value = (setting.value || {}).merge(key => value)
    setting.save
  end

  def self.set_special_user(role, username)
    Setting.set_hash('special_users', role.to_sym, username)
  end

  def self.remove_special_user(role)
    users = Setting.find_or_create_by(key: 'special_users')
    users.value.delete(role.to_sym)
    users.save
  end
end
