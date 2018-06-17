# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/analytics/campaign_edits_csv_builder"

describe CampaignEditsCsvBuilder do
  let(:campaign) { create(:campaign) }
  let(:course) { create(:course) }
  let(:edits) { CampaignEditsCsvBuilder.new(campaign).generate_csv }

  it 'creates a CSV with a header' do
    expect(edits).to include("revision_id")
    expect(edits).to include("campaign")
    expect(edits).to include("course")
    expect(edits).to include("timestamp")
    expect(edits).to include("wiki")
    expect(edits).to include("article_title")
    expect(edits).to include("username")
    expect(edits).to include("bytes_added")
    expect(edits).to include("new_article")
    expect(edits).to include("dashboard_edit")
  end

end
