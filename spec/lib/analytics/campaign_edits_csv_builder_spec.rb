# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/analytics/campaign_edits_csv_builder"

describe CampaignEditsCsvBuilder do
  let(:campaign) { create(:campaign) }
  let(:course) { create(:course) }
  let(:user) { create(:user) }
  let(:article) { create(:article) }
  let!(:revision) { create(:revision, article: article, user: user, date: course.start + 1.hour) }
  before do
    campaign.courses << course
    create(:courses_user, course: course, user: user)
  end
  let(:edits) { described_class.new(campaign).generate_csv }

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

  it 'creates a CSV with a header and a row of data for a course revision' do
    expect(edits.split("\n").count).to eq(2)
  end

  it 'creates a CSV with a header and a row of data for a course revision' do
    expect(edits).to include(course.title)
    expect(edits).to include(article.title)
  end
end
