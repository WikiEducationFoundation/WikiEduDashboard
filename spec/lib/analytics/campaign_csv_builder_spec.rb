# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/analytics/campaign_csv_builder"

describe CampaignCsvBuilder do
  let(:campaign) { Campaign.first }
  let(:open_course) { create(:course, slug: 'Open/Open_course_(term)') }
  let(:hidden_course) { create(:course, slug: 'Hidden/Hidden_course_(term)', private: true) }

  before do
    campaign.courses << open_course
    campaign.courses << hidden_course
  end

  describe '#courses_to_csv' do
    it 'leaves out private courses' do
      csv = described_class.new(campaign).courses_to_csv
      expect(csv).to include('Open_course')
      expect(csv).not_to include('Hidden_course')
    end
  end
end
