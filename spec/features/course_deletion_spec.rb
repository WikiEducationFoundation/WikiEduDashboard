# frozen_string_literal: true

require 'rails_helper'

describe 'course deletion', type: :feature, js: true do
  let(:course) { create(:course) }
  let(:admin) { create(:admin, locale: 'en') }
  let(:second_campaign) { create(:campaign, slug: 'second_campaign') }

  it 'destroys the course and redirects to the home page' do
    login_as admin
    stub_oauth_edit
    visit "/courses/#{course.slug}"

    expect(Course.count).to eq(1)

    # wait for all the json requests to resolve before deleting
    sleep 1

    accept_prompt(with: course.title) do
      click_button 'Delete course'
    end
    expect(page).to have_content 'Create Course'
    expect(Course.count).to eq(0)
  end

  context 'when it is in a campaign' do
    before do
      course.campaigns << Campaign.first
    end

    it 'delists the course from the campaign page' do
      login_as admin
      stub_oauth_edit
      visit "campaigns/#{Campaign.first.slug}/programs"
      expect(page).to have_content course.title
      accept_prompt(with: course.title) do
        click_button 'Remove and Delete'
      end
      expect(page).to have_content 'has been deleted and removed'
      sleep 1
      expect(Course.count).to eq(0)
    end
  end

  context 'when it is in multiple campaigns' do
    before do
      course.campaigns << Campaign.first
      course.campaigns << second_campaign
    end

    it 'delists the course from one campaign page' do
      login_as admin
      stub_oauth_edit
      visit "campaigns/#{Campaign.first.slug}/programs"
      expect(page).to have_content course.title
      accept_prompt(with: course.title) do
        click_button 'Remove and Delete'
      end
      expect(page).to have_content 'but has not been deleted'
      sleep 1
      expect(course.reload.campaigns.count).to eq(1)
    end
  end
end
