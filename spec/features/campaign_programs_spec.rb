# frozen_string_literal: true
require 'rails_helper'

describe 'campaign programs page', type: :feature, js: true do
  let(:slug)  { 'spring_2016' }
  let(:user)  { create(:user) }
  let(:campaign) { create(:campaign) }
  let(:course) { create(:course) }
  let!(:campaigns_course) do
    create(:campaigns_course, campaign_id: campaign.id,
                              course_id: course.id)
  end

  # tests for whether Remove button should be shown live in CampaignsControllerSpec
  context 'remove program' do
    it 'should remove a program from the campaign via the remove button' do
      admin = create(:admin)
      login_as(admin, scope: :user)
      visit "/campaigns/#{campaign.slug}/programs"
      expect(page).to have_css('.remove-course')
      alert_message = I18n.t('campaign.confirm_course_removal', title: course.title,
                                                                campaign_title: campaign.title)
      page.accept_alert alert_message do
        find('.remove-course').click
      end
      expect(page).to have_content('has been removed')
      expect(CampaignsCourses.find_by_id(campaigns_course.id)).to be_nil
    end
  end
end
