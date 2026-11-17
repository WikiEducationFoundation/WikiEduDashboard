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

    it 'includes private courses in the variant for admins and organizers' do
      csv = described_class.new(campaign, include_private: true).courses_to_csv
      expect(csv).to include('Open_course')
      expect(csv).to include('Hidden_course')
    end
  end

  describe '#wikidata_to_csv' do
    before do
      create(:course_stats, course: hidden_course,
                           stats_hash: { 'www.wikidata.org' => { 'claims created' => 3 } })
    end

    it 'leaves out private courses' do
      csv = described_class.new(campaign).wikidata_to_csv
      expect(csv).not_to include(hidden_course.title)
    end

    it 'includes private courses in the variant for admins and organizers' do
      csv = described_class.new(campaign, include_private: true).wikidata_to_csv
      expect(csv).to include(hidden_course.title)
    end
  end
end
