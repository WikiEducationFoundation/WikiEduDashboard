# frozen_string_literal: true

require 'rails_helper'

describe 'course deletion', type: :feature, js: true do
  let(:course) { create(:course) }
  let(:admin) { create(:admin) }
  let(:second_campaign) { create(:campaign, slug: 'second_campaign') }

  before do
    Rails.cache.clear
  end

  it 'destroys the course and redirects to the home page' do
    login_as admin
    stub_oauth_edit
    visit "/courses/#{course.slug}"

    expect(Course.count).to eq(1)

    # wait for all the json requests to resolve before deleting
    sleep 1

    accept_prompt(with: course.title) do
      # Using class because the text is translated
      find('.available-action button.danger').click
    end
    expect(page).to have_content(/Create Course|Criar curso/i)
    expect(Course.count).to eq(0)
  end

  context 'when it is in a campaign' do
    before do
      course.campaigns << Campaign.first
    end

    # P&E offers instructors deletion of a course that is in a campaign. The
    # course page deletes it directly: removing a course from a campaign is for
    # the campaign's organizers (Courses::DeleteFromCampaignController).
    it 'lets the course\'s instructor delete it on P&E' do
      allow(Features).to receive(:wiki_ed?).and_return(false)
      instructor = create(:user, username: 'DeletingInstructor')
      create(:courses_user, course:, user: instructor,
                            role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
      login_as instructor
      stub_oauth_edit
      visit "/courses/#{course.slug}"
      sleep 1

      accept_prompt(with: course.title) do
        find('.available-action button.danger').click
      end
      expect(page).to have_current_path('/')
      expect(Course.count).to eq(0)
    end

    it 'delists the course from the campaign page' do
      login_as admin
      stub_oauth_edit
      # Stats are only shown on the overview page
      visit "/campaigns/#{Campaign.first.slug}/overview"
      within '#courses-count' do
        expect(page).to have_content '1'
      end

      visit "/campaigns/#{Campaign.first.slug}/programs"
      expect(page).to have_content course.title
      accept_prompt(with: course.title) do
        find('button.delete-course-from-campaign').click
      end
      within '#courses' do
        expect(page).not_to have_content course.title
      end

      visit "/campaigns/#{Campaign.first.slug}/refresh"
      within '#courses-count' do
        expect(page).to have_content '0'
      end
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
      # Stats are only shown on the overview page
      visit "/campaigns/#{Campaign.first.slug}/overview"
      within '#courses-count' do
        expect(page).to have_content '1'
      end

      visit "/campaigns/#{Campaign.first.slug}/programs"
      expect(page).to have_content course.title
      accept_prompt(with: course.title) do
        find('button.delete-course-from-campaign').click
      end
      within '#courses' do
        expect(page).not_to have_content course.title
      end

      visit "/campaigns/#{Campaign.first.slug}/refresh"
      within '#courses-count' do
        expect(page).to have_content '0'
      end
      expect(course.reload.campaigns.count).to eq(1)
    end
  end
end
