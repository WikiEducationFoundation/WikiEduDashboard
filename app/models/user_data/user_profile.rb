# frozen_string_literal: true
# == Schema Information
#
# Table name: user_profiles
#
#  id                 :integer          not null, primary key
#  bio                :text(65535)
#  user_id            :integer
#  image_file_name    :string(255)
#  image_content_type :string(255)
#  image_file_size    :bigint
#  image_updated_at   :datetime
#  location           :string(255)
#  institution        :string(255)
#  email_preferences  :text(65535)
#  image_file_link    :string(255)
#

class UserProfile < ApplicationRecord
  belongs_to :user
  has_attached_file :image, styles: { thumb: '150x150>' }
  validates_attachment_content_type :image, content_type: %r{\Aimage/.*\z}
  serialize :email_preferences, Hash

  def email_preferences_token
    set_email_preferences_token unless email_preferences.key?(:token)
    email_preferences[:token]
  end

  def email_opt_out(type)
    validate_email_type(type)
    email_preferences[type] = false
    save
  end

  def email_allowed?(type)
    return true unless email_preferences.key?(type)
    email_preferences[type]
  end

  private

  def set_email_preferences_token
    email_preferences[:token] = GeneratePasscode.call(length: 16)
    save
  end

  VALID_EMAIL_PREFERENCES = [
    'OverdueTrainingAlert'
  ].freeze

  def validate_email_type(type)
    return if VALID_EMAIL_PREFERENCES.include?(type)
    raise InvalidEmailPreferencesType, "#{type} is not a known email preference."
  end

  class InvalidEmailPreferencesType < StandardError; end
end
