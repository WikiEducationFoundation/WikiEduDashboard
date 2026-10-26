# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/analytics/campaign_csv_builder"

describe CampaignCsvBuilder do
  describe '#courses_to_csv' do
    let(:campaign) { Campaign.first }

    before do
      campaign.courses << create(:course, slug: 'Open/Open_course_(term)')
      campaign.courses << create(:course, slug: 'Hidden/Hidden_course_(term)', private: true)
    end

    it 'leaves out private courses' do
      csv = described_class.new(campaign).courses_to_csv
      expect(csv).to include('Open_course')
      expect(csv).not_to include('Hidden_course')
    end
  end
end
