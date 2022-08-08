# frozen_string_literal: true

require 'rails_helper'

describe 'dashboard', type: :feature, js: true do
  before { TrainingModule.load_all }

  let(:user) do
    create(:user,
           onboarded: true, real_name: 'test',
           email: 'email@email.com', permissions:)
  end

  context 'with no courses' do
    describe 'for students' do
      let(:permissions) { User::Permissions::NONE }

      before do
        login_as(user, scope: :user)
      end

      it 'describes joining a course' do
        visit root_path
        expect(page).to have_content 'Once you receive a passcode'
      end
    end

    describe 'for instructors' do
      let(:permissions) { User::Permissions::INSTRUCTOR }

      before do
        login_as(user, scope: :user)
      end

      it 'links to orientation' do
        visit root_path
        expect(page).to have_content 'Before you create a course, let\'s go through orientation'
      end

      it 'allows creating a course if they\'ve completed orientation' do
        create(:training_modules_users,
               user_id: user.id,
               training_module_id: 3,
               completed_at: Time.zone.now)
        visit root_path
        expect(page).to have_content 'Click on Create Course to create your first course'
      end
    end
  end

  context 'populated with courses' do
    context 'for returning instructors' do
      let(:permissions) { User::Permissions::INSTRUCTOR }

      before do
        login_as(user, scope: :user)
      end

      it 'allows creation of second course even if orientation is not complete' do
        create(:course,
               id: 10001,
               title: 'Course',
               school: 'University',
               term: 'Term',
               slug: 'University/Course_(Term)',
               submitted: false,
               passcode: 'passcode',
               start: '2015-08-24'.to_date,
               end: '2015-12-15'.to_date,
               timeline_start: '2015-08-31'.to_date,
               timeline_end: '2015-12-15'.to_date)
        create(:courses_user,
               user_id: user.id,
               course_id: 10001,
               role: 1)
        visit root_path
        expect(page).to have_content 'Create Course'
      end
    end

    context 'as a Wiki Education Foundation admin' do
      let(:permissions) { User::Permissions::SUPER_ADMIN }

      before do
        allow(Features).to receive(:wiki_ed?).and_return(true)
        login_as(user, scope: :user)
      end

      it 'displays overview information for upcoming courses' do
        create(:course,
               id: 10001,
               title: 'Title',
               school: 'University',
               term: 'Term',
               slug: 'University/Course_(Term)',
               submitted: false,
               passcode: 'passcode',
               start: 1.day.from_now,
               end: 60.days.from_now,
               timeline_start: 20.days.from_now,
               timeline_end: 60.days.from_now)
        create(:courses_user,
               user_id: user.id,
               course_id: 10001,
               role: 4)
        visit root_path
        expect(page).to have_content 'Courses'
        expect(page).to have_content 'Recent Edits'
        expect(page).to have_content 'Words Added'
        expect(page).to have_content 'Views'
        expect(page).to have_content 'Editors'
        expect(page).to have_content 'Ungreeted'
      end
    end
  end

  context 'archived courses' do
    let(:permissions) { User::Permissions::INSTRUCTOR }

    before do
      login_as(user, scope: :user)
    end

    it 'does not initially show archived' do
      visit root_path
      expect(page).not_to have_content 'Archived Courses'
    end

    it 'show archived courses when there are past courses for the user' do
      create(:course,
             id: 10001,
             title: 'Archived Title',
             school: 'University',
             term: 'Term',
             slug: 'University/Course_(Term)',
             submitted: false,
             passcode: 'passcode',
             start: '2010-08-24'.to_date,
             end: '2011-12-15'.to_date,
             timeline_start: '2010-08-31'.to_date,
             timeline_end: '2011-12-15'.to_date)
      create(:courses_user,
             user_id: user.id,
             course_id: 10001,
             role: 1)
      visit root_path
      expect(page).to have_content 'Archived Courses'
      expect(page).to have_content 'Archived Title'
    end

    it 'shows both archived and non-archived' do
      create(:course,
             id: 10001,
             title: 'Archived Title',
             school: 'University',
             term: 'Term',
             slug: 'University/Course_(Term)',
             submitted: false,
             passcode: 'passcode',
             start: '2010-08-24'.to_date,
             end: '2011-12-15'.to_date)
      create(:courses_user,
             user_id: user.id,
             course_id: 10001,
             role: 1)
      create(:course,
             id: 10002,
             title: 'Recent Title',
             school: 'University',
             term: 'Term',
             slug: 'University/Course2_(Term)',
             submitted: false,
             passcode: 'passcode',
             start: Time.zone.now,
             end: Time.zone.now + 100.days)
      create(:courses_user,
             user_id: user.id,
             course_id: 10002,
             role: 1)
      visit root_path
      expect(page).to have_content 'Archived Courses'
      expect(page).to have_content 'Archived Title'
      expect(page).to have_content 'Your Courses'
      expect(page).to have_content 'Recent Title'
    end
  end

  context 'campaigns' do
    let(:permissions) { User::Permissions::NONE }

    before do
      create(:campaign) # arbitrary campaign
      login_as(user, scope: :user)
    end

    it "does not show a campaigns section if the user isn't organizing any campaigns" do
      visit root_path
      expect(page).not_to have_content(I18n.t('campaign.campaigns'))
    end

    it 'lists campaigns the user organizes' do
      campaign = create(:campaign, title: 'My awesome campaign')
      create(:campaigns_user, user_id: user.id,
                              campaign_id: campaign.id,
                              role: CampaignsUsers::Roles::ORGANIZER_ROLE)
      visit root_path
      expect(page).to have_content(campaign.title)
    end
  end
end
