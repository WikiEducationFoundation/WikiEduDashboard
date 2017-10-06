# frozen_string_literal: true

require 'rails_helper'

describe 'campaign programs page', type: :feature, js: true do
  let(:slug)  { 'spring_2016' }
  let(:user)  { create(:user) }
  let(:campaign) { create(:campaign) }
  let(:course) do
    create(:course, title: 'Basket-weaving',
                    school: 'AAA',
                    slug: 'AAA/Basket-weaving_(spring_2016)')
  end
  let(:course2) do
    create(:course, title: 'Advanced basket-weaving',
                    school: 'ZZZ',
                    slug: 'ZZZ/Advanced_basket-weaving_(spring_2016)')
  end
  let!(:campaigns_course) do
    create(:campaigns_course, campaign_id: campaign.id,
                              course_id: course.id)
  end
  let!(:campaigns_course2) do
    create(:campaigns_course, campaign_id: campaign.id,
                              course_id: course2.id)
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
        all('.remove-course')[1].click
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
      find('#courses [data-sort="title"].sort').click
      expect(page).to have_selector('#courses [data-sort="title"].sort.desc')

      # Sortable by institution
      find('#courses [data-sort="school"].sort').click
      expect(page).to have_selector('#courses [data-sort="school"].sort.asc')
      find('#courses [data-sort="school"].sort').click
      expect(page).to have_selector('#courses [data-sort="school"].sort.desc')
    end

    def expect_advanced_before_regular_basketweaving
      expect(page.find(:xpath, '//tbody/tr[1]')).to have_content 'Advanced basket-weaving'
      expect(page.find(:xpath, '//tbody/tr[2]')).to have_content 'Basket-weaving'
    end

    def expect_regular_before_advanced_basketweaving
      expect(page.find(:xpath, '//tbody/tr[1]')).to have_content 'Basket-weaving'
      expect(page.find(:xpath, '//tbody/tr[2]')).to have_content 'Advanced basket-weaving'
    end

    it 'should sort the contained courses' do
      visit "/campaigns/#{campaign.slug}/programs"

      expect_advanced_before_regular_basketweaving
      find('#courses [data-sort="title"].sort').click
      expect_regular_before_advanced_basketweaving

      find('#courses [data-sort="school"].sort').click
      expect_regular_before_advanced_basketweaving
      find('#courses [data-sort="school"].sort').click
      expect_advanced_before_regular_basketweaving
    end
  end
end
