require 'rails_helper'

describe 'dashboard', type: :feature, js: true do
  let(:user) { create(:user, onboarded: true, real_name: 'test', email: 'email@email.com', permissions: permissions) }

  before do
    create(:cohort)
  end

  describe 'empty state' do

    describe 'for students' do
      let(:permissions) { User::Permissions::NONE }

      before :each do
        login_as(user, scope: :user)
      end

      it 'should describe joining a course' do
        visit root_path
        expect(page).to have_content 'Once you receive a passcode'
      end
    end

    describe 'for instructors' do
      let(:permissions) { User::Permissions::INSTRUCTOR }

      before :each do
        login_as(user, scope: :user)
      end

      it 'should link to orientation' do
        visit root_path
        expect(page).to have_content 'Before you create a course, let\'s go through orientation'
      end

      it 'should allow creating a course if they\'ve completed orientation' do
        tmu = create(:training_modules_users, user_id: user.id, training_module_id: 3, completed_at: Time.now)
        visit root_path
        expect(page).to have_content 'Click on Create Course to create your first course'
      end

    end

  end

  describe 'populated' do

    describe 'for instructors' do

      let(:permissions) { User::Permissions::INSTRUCTOR }

      before :each do
        login_as(user, scope: :user)
      end

      it 'should allow creating a course if they haven\'t completed orientation but they already have a course' do
        create(:course,
             id: 10001,
             title: 'Course',
             school: 'University',
             term: 'Term',
             slug: 'University/Course_(Term)',
             submitted: 0,
             listed: true,
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

  end

  describe 'archived course' do
    let(:permissions) { User::Permissions::INSTRUCTOR }

    before :each do
      login_as(user, scope: :user)
    end

    it 'should not initially show archived' do
      visit root_path
      expect(page).not_to have_content 'Archived Courses'
    end

    it 'should show archived courses when there are archived courses' do
      create(:course,
             id: 10001,
             title: 'Archived Title',
             school: 'University',
             term: 'Term',
             slug: 'University/Course_(Term)',
             submitted: 0,
             listed: true,
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

    it 'should show both archived and non-archived' do
      create(:course,
           id: 10001,
           title: 'Archived Title',
           school: 'University',
           term: 'Term',
           slug: 'University/Course_(Term)',
           submitted: 0,
           listed: true,
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
           slug: 'University/Course_(Term)',
           submitted: 0,
           listed: true,
           passcode: 'passcode',
           start: Time.now,
           end: Time.now + 100.days)
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


end
