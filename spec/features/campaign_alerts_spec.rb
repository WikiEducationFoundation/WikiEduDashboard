# frozen_string_literal: true

require 'rails_helper'

describe 'campaign alerts page', type: :feature, js: true do
  let(:slug) { 'spring_2016' }
  let(:course) { create(:course) }
  let(:campaign) { create(:campaign) }
  let!(:campaigns_course) do
    create(:campaigns_course, campaign_id: campaign.id,
                              course_id: course.id)
  end
  let!(:afd_alert) do
    create(:alert, type: 'ArticlesForDeletionAlert', course: course)
  end

  it 'shows users in the campaign courses' do
    visit "/campaigns/#{campaign.slug}/alerts"
    expect(page).to have_content('ArticlesForDeletionAlert')
  end
end
