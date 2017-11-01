# frozen_string_literal: true

# == Schema Information
#
# Table name: campaigns_users
#
#  id          :integer          not null, primary key
#  campaign_id :integer
#  user_id     :integer
#  role        :integer          default(0)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

FactoryBot.define do
  factory :campaigns_user, class: 'CampaignsUsers' do
    nil
  end
end
