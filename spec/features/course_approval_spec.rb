# frozen_string_literal: true

require 'rails_helper'

describe 'Course Approval', type: :feature, js: true do
  let(:program_manager) { create(:user, username: 'Program Manager') }
  let(:wiki_expert) { create(:user, username: 'Wiki Expert') }

  before do
    page.current_window.resize_to(1920, 1080)

    # Create a course starting in January 2022 (Spring 2022)
    create(:course,
           id: 10001,
           title: 'My Course',
           school: 'University',
           term: 'Term',
           slug: 'University/Course_(Term)',
           submitted: true,
           start: '2022-01-01'.to_date,
           end: '2022-06-30'.to_date)

    # Create special users
    SpecialUsers.set_user('classroom_program_manager', program_manager.username)
    SpecialUsers.set_user('wikipedia_experts', wiki_expert.username)
  end

  after do
    logout
  end

  describe 'non-admin user' do
    let(:user) { create(:user) }

    before do
      login_as(user)
    end

    it 'does not see course approval form' do
      visit "/courses/#{Course.first.slug}"
      expect(page).not_to have_content 'Course Approval Form'
    end
  end

  describe 'admin user' do
    let(:admin) { create(:admin) }

    before do
      login_as(admin)
      stub_oauth_edit
    end

    it 'sees course approval form' do
      visit "/courses/#{Course.first.slug}"
      expect(page).to have_content 'Course Approval Form'
    end

    # If suitable campaign is not inferred and not selected by default, submit button is disabled
    describe 'with campaign not inferred' do
      # Create a campaign belonging to Fall 2022 season
      before do
        create(:campaign, title: 'Fall 2022', slug: 'fall_2022')
      end

      it 'has submit button disabled' do
        visit "/courses/#{Course.first.slug}"
        within('.module.course-approval .section-header .controls') do
          expect(page).to have_css('button.dark.disabled')
        end
      end
    end

    # Submit button is clickable when campaign is inferred by default (or manually selected)
    describe 'with campaign inferred' do
      # Create a campaign belonging to Spring 2022 season
      before do
        create(:campaign, title: 'Spring 2022', slug: 'spring_2022')
      end

      it 'has submit button enabled' do
        visit "/courses/#{Course.first.slug}"
        within('.module.course-approval .section-header .controls') do
          expect(page).not_to have_css('button.dark.disabled')
          expect(page).to have_css('button.dark')
        end
      end

      it 'submits the form' do
        visit "/courses/#{Course.first.slug}"
        click_button 'Approve Course'
        expect(page).to have_content 'Your course has been published'
        # rubocop:disable Layout/LineLength
        expect(page).not_to have_content 'This course has been submitted for approval by its creator'
        # rubocop:enable Layout/LineLength
      end
    end
  end
end
