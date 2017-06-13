# frozen_string_literal: true

require 'rails_helper'

describe 'campaign users page', type: :feature, js: true do
  let(:slug)  { 'spring_2016' }
  let(:user)  { create(:user, username: 'ExampleUser') }
  let(:campaign) { create(:campaign) }
  let(:course) { create(:course) }
  let(:article) { create(:article, title: 'ExampleArticle') }
  let!(:courses_user) { create(:courses_user, course: course, user: user) }
  let!(:campaigns_course) do
    create(:campaigns_course, campaign_id: campaign.id,
                              course_id: course.id)
  end

  it 'shows users in the campaign courses' do
    visit "/campaigns/#{campaign.slug}/users"
    expect(page).to have_content('ExampleUser')
  end
end
