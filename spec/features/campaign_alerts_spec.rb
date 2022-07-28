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
    create(
      :alert,
      type: 'ArticlesForDeletionAlert',
      course: course,
      created_at: '2020-05-29T15:21:53.000Z'
    )
  end

  it 'shows users in the campaign courses' do
    visit "/campaigns/#{campaign.slug}/alerts"
    expect(page).to have_content('ArticlesForDeletionAlert')
    time_str = format_local_datetime afd_alert.created_at
    expect(page).to have_content(time_str)
  end
end
