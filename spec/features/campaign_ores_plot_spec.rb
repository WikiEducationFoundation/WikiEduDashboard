# frozen_string_literal: true

require 'rails_helper'

describe 'campaign ORES plot tab', type: :feature, js: true do
  let(:slug) { 'spring_2016' }
  let(:course) { create(:course) }
  let(:campaign) { create(:campaign) }
  let!(:campaigns_course) do
    create(:campaigns_course, campaign_id: campaign.id,
                              course_id: course.id)
  end

  it 'render the structural completeness component and fetches data' do
    visit "/campaigns/#{campaign.slug}/ores_plot"
    click_button 'Change in Structural Completeness'
    expect(page).to have_content('This graph visualizes')
  end
end
