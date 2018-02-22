# frozen_string_literal: true

# == Schema Information
#
# Table name: requested_accounts
#
#  id         :integer          not null, primary key
#  course_id  :integer
#  username   :string(255)
#  email      :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class RequestedAccount < ApplicationRecord
  belongs_to :course
  belongs_to :campaign
  before_validation :ensure_valid_email

  private

  def ensure_valid_email
    self.email = nil if ValidatesEmailFormatOf::validate_email_format(email)
  end
end
