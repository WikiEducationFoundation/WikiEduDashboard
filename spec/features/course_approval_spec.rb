# frozen_string_literal: true

require 'rails_helper'

describe 'Course Approval', type: :feature, js: true do
  let(:program_manager) { create(:user, username: 'Program Manager') }
  let(:wiki_expert) { create(:user, username: 'Wiki Expert') }

  # Course starting in January 2022 (Spring 2022)
  let!(:course) do
    create(:course,
           title: 'My Course',
           school: 'University',
           term: 'Term',
           slug: 'University/Course_(Term)',
           submitted: true,
           start: '2022-01-01'.to_date,
           end: '2022-06-30'.to_date)
  end

  before do
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
      visit "/courses/#{course.slug}"
      expect(page).not_to have_content 'Course Approval Form'
    end
  end

  describe 'admin user' do
    let(:admin) { create(:admin) }

    before do
      login_as(admin)
      stub_oauth_edit
    end

    # If suitable campaign is not inferred and not selected by default, submit button is disabled
    describe 'with campaign not inferred' do
      # Create a campaign belonging to Fall 2022 season
      before do
        create(:campaign, title: 'Fall 2022', slug: 'fall_2022')
      end

      it 'has submit button disabled' do
        visit "/courses/#{course.slug}"
        expect(page).to have_content 'Course Approval Form'
        within('.module.course-approval .section-header .controls') do
          expect(page).to have_css('button.dark.disabled')
        end
        sleep 1 # Workaround: possible race condition if all update requests haven't completed yet
      end
    end

    describe 'declining a course' do
      it 'marks the course as declined after confirming' do
        visit "/courses/#{course.slug}"
        expect(page).to have_content 'Course Approval Form'
        accept_confirm do
          click_button 'Decline Course'
        end
        expect(page).to have_content 'This course has been declined'
        expect(course.reload.flags[:declined]).to be true
        expect(course.submitted).to be false
      end
    end

    # Submit button is clickable when campaign is inferred by default (or manually selected)
    describe 'with campaign inferred' do
      # Create a campaign belonging to Spring 2022 season
      before do
        create(:campaign, title: 'Spring 2022', slug: 'spring_2022')
      end

      it 'has submit button enabled and works' do
        visit "/courses/#{course.slug}"
        expect(page).to have_content 'This course has been submitted'
        within('.module.course-approval .section-header .controls') do
          expect(page).not_to have_css('button.dark.disabled')
          expect(page).to have_css('button.dark')
        end
        click_button 'Approve Course'
        expect(page).to have_content 'Your course has been published'
        expect(page).not_to have_content 'This course has been submitted'
        sleep 1 # Workaround: possible race condition if all update requests haven't completed yet
      end
    end
  end
end
