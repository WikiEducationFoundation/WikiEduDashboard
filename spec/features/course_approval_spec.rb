# frozen_string_literal: true

require 'rails_helper'

describe 'Course Approval', type: :feature, js: true do
  let(:program_manager) { create(:user, username: 'Program Manager') }
  let(:wiki_expert) { create(:user, username: 'Wiki Expert') }

  before do
    page.current_window.resize_to(1920, 1080)
    create(:course,
           id: 10001,
           title: 'My Course',
           school: 'University',
           term: 'Term',
           slug: 'University/Course_(Term)',
           submitted: true,
           start: '2022-01-01'.to_date,
           end: '2022-06-30'.to_date)

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

    describe 'with campaign not inferred' do
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

    describe 'with campaign inferred' do
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
        expect(page).not_to have_content 'This course has been submitted for approval by its creator'
      end
    end
  end
end
