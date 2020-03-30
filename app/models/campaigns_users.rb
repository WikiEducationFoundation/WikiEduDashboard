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

#= Campaign + User join model
class CampaignsUsers < ApplicationRecord
  belongs_to :campaign
  belongs_to :user

  # rubocop:disable Rails/UniqueValidationWithoutIndex
  validates :campaign_id, uniqueness: { scope: %i[user_id role] }
  # rubocop:enable Rails/UniqueValidationWithoutIndex

  ##############
  # CONSTANTS  #
  ##############

  module Roles
    ORGANIZER_ROLE = 1
  end
end
