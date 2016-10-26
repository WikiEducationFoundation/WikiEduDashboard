# frozen_string_literal: true
require 'rails_helper'
require "#{Rails.root}/lib/legacy_courses/legacy_campaign_importer"

describe LegacyCampaignImporter do
  describe '.update_campaigns' do
    it 'should add and remove courses from campaigns' do
      (1..6).each do |i|
        create(:legacy_course, id: i)
      end
      campaign_data = {
        'campaign_1' => [1, 2, 3],
        'campaign_2' => [3, 4, 5]
      }
      LegacyCampaignImporter.update_campaigns(campaign_data)
      campaign_1 = Campaign.where(slug: 'campaign_1').first
      campaign_2 = Campaign.where(slug: 'campaign_2').first
      expect(campaign_1.courses.all.count).to eq(3)
      expect(campaign_2.courses.all.count).to eq(3)

      campaign_data = {
        'campaign_1' => [1, 2],
        'campaign_2' => [3, 4, 5, 6]
      }
      LegacyCampaignImporter.update_campaigns(campaign_data)
      expect(campaign_1.courses.all.count).to eq(2)
      expect(campaign_2.courses.all.count).to eq(4)
    end
  end
end
