# frozen_string_literal: true
# == Schema Information
#
# Table name: campaigns
#
#  id         :integer          not null, primary key
#  title      :string(255)
#  slug       :string(255)
#  url        :string(255)
#  created_at :datetime
#  updated_at :datetime
#

require 'rails_helper'

describe Campaign do
  describe '.initialize_campaigns' do
    it 'create campaigns from application.yml' do
      Campaign.destroy_all
      campaigns = Campaign.all
      expect(campaigns).to be_empty

      Campaign.initialize_campaigns
      campaign = Campaign.first
      expect(campaign.url).to be_a(String)
      expect(campaign.title).to be_a(String)
      expect(campaign.slug).to be_a(String)

      # Make sure it still works if all the campaigns already exist
      Campaign.initialize_campaigns
    end
  end

  describe '.default_campaign' do
    it 'returns a campaign' do
      expect(Campaign.default_campaign).to be_a(Campaign)
    end
  end

  describe 'association' do
    it { should have_many(:question_group_conditionals) }
    it { should have_many(:rapidfire_question_groups).through(:question_group_conditionals) }
  end
end
