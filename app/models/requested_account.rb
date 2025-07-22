# frozen_string_literal: true
# == Schema Information
#
# Table name: requested_accounts
#
#  id         :bigint           not null, primary key
#  course_id  :integer
#  username   :string(255)
#  email      :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class RequestedAccount < ApplicationRecord
  belongs_to :course
  belongs_to :campaign
  validate :email_format

  def invalid_email_message
    "'#{email}' is not a valid email address."
  end

  def updated_email_message
    'The email for this requested username has been updated.'
  end

  private

  def email_format
    return unless ValidatesEmailFormatOf::validate_email_format(email)
    errors.add(:email, invalid_email_message)
  end
end
