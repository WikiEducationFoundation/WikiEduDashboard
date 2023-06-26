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

FactoryBot.define do
  factory :requested_account do
  end
end
