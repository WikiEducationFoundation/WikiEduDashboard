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
      course:,
      created_at: '2020-05-29T15:21:53.000Z'
    )
  end

  it 'shows users in the campaign courses' do
    visit "/campaigns/#{campaign.slug}/alerts"
    expect(page).to have_content('ArticlesForDeletionAlert')
    time_str = format_local_datetime afd_alert.created_at
    expect(page).to have_content(time_str)
  end

  # As the url is intented to be a bookmark, the test
  # is the same as above (shows users in the campaign courses)
  # since there is for now in test only one campaign
  it 'shows alerts from the current campaign' do
    # By default in test, it is 'spring_2015', so set to the last Campaign
    CampaignsPresenter.update_default_campaign(slug)
    visit 'campaigns/current/alerts'
    expect(page).to have_content('ArticlesForDeletionAlert')
    time_str = format_local_datetime afd_alert.created_at
    expect(page).to have_content(time_str)
  end
end
