# frozen_string_literal: true
# == Schema Information
#
# Table name: campaigns_users
#
#  id          :integer          not null, primary key
#  created_at  :datetime
#  updated_at  :datetime
#  campaign_id :integer
#  user_id     :integer
#  role        :integer          default(0)
#

require 'rails_helper'

describe CampaignsUsers, type: :model do

end
