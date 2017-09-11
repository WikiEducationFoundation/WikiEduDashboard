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

  describe 'control bar' do
    it 'should allow sorting using a dropdown' do
      visit "/campaigns/#{campaign.slug}/programs"

      find('#courses select.sorts').find(:xpath, 'option[1]').select_option
      expect(page).to have_selector('[data-sort="title"].sort.asc')
      find('#courses select.sorts').find(:xpath, 'option[2]').select_option
      expect(page).to have_selector('[data-sort="school"].sort.asc')
      find('#courses select.sorts').find(:xpath, 'option[3]').select_option
      expect(page).to have_selector('[data-sort="revisions"].sort.desc')
      find('#courses select.sorts').find(:xpath, 'option[4]').select_option
      expect(page).to have_selector('[data-sort="characters"].sort.desc')

      find('#courses select.sorts').find(:xpath, 'option[6]').select_option
      expect(page).to have_selector('[data-sort="views"].sort.desc')
      find('#courses select.sorts').find(:xpath, 'option[7]').select_option
      expect(page).to have_selector('[data-sort="students"].sort.desc')
    end
  end

  describe 'course list' do
    it 'should be sortable by the different selectors' do
      visit "/campaigns/#{campaign.slug}/programs"

      # Sortable by title
      expect(page).to have_selector('#courses [data-sort="title"].sort.asc')
      find('#courses [data-sort="title"].sort').trigger('click')
      expect(page).to have_selector('#courses [data-sort="title"].sort.desc')

      # Sortable by institution
      find('#courses [data-sort="school"].sort').trigger('click')
      expect(page).to have_selector('#courses [data-sort="school"].sort.asc')
      find('#courses [data-sort="school"].sort').trigger('click')
      expect(page).to have_selector('#courses [data-sort="school"].sort.desc')
    end
  end
end
