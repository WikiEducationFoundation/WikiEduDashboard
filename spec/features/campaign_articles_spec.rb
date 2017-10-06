# frozen_string_literal: true

require 'rails_helper'

describe 'campaign articles page', type: :feature, js: true do
  let(:slug)  { 'spring_2016' }
  let(:user)  { create(:user) }
  let(:campaign) { create(:campaign) }
  let(:course) { create(:course) }
  let(:article) { create(:article, title: 'ExampleArticle') }
  let!(:articles_course) { create(:articles_course, course: course, article: article) }
  let!(:campaigns_course) do
    create(:campaigns_course, campaign_id: campaign.id,
                              course_id: course.id)
  end

  it 'shows articles edited by campaign courses' do
    visit "/campaigns/#{campaign.slug}/articles"
    expect(page).to have_content('ExampleArticle')
  end
end
