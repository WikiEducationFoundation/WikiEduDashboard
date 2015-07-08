require 'rails_helper'

describe 'Admin users', type: :feature, js: true do
  before do
    include Devise::TestHelpers, type: :feature
    Capybara.current_driver = :selenium
  end

  before :each do
    create(:user,
           id: 100,
           wiki_id: 'Professor Sage')

    create(:course,
           id: 10001,
           title: 'My Submitted Course',
           school: 'University',
           term: 'Term',
           slug: 'University/Course_(Term)',
           submitted: 1,
           listed: true,
           passcode: 'passcode',
           start: '2015-01-01'.to_date,
           end: '2020-01-01'.to_date)
    create(:courses_user,
           user_id: 100,
           course_id: 10001,
           role: 1)

    create(:course,
           id: 10002,
           title: 'My Unsubmitted Course',
           school: 'University',
           term: 'Term',
           slug: 'University/Course_(Term)',
           submitted: 0,
           listed: true,
           passcode: 'passcode',
           start: '2015-01-01'.to_date,
           end: '2020-01-01'.to_date)
    create(:courses_user,
           user_id: 100,
           course_id: 10002,
           role: 1)

    create(:cohort,
           id: 1,
           title: 'Fall 2015')
    user = create(:admin,
                  id: 200,
                  wiki_token: 'foo',
                  wiki_secret: 'bar')
    login_as(user, scope: :user)
  end

  describe 'visiting the homepage' do
    it 'should see submitted courses awaiting approval' do
      visit root_path
      sleep 1
      expect(page).to have_content 'Submitted Courses'
      expect(page).to have_content 'My Submitted Course'
    end
  end

  describe 'adding a course to cohort' do
    it 'should make the course live' do
      stub_oauth_edit

      visit "/courses/#{Course.first.slug}"
      sleep 1

      # Edit details and add cohort
      page.all('.button.dark')[1].click
      page.all('.button.border.plus')[4].click
      find('.pop input', visible: true).set('Fall 2015')
      find('.pop button', visible: true).click
      page.driver.browser.switch_to.alert.accept
      page.driver.browser.switch_to.alert.accept
      sleep 1

      expect(page).to have_content 'Your course has been published'

      visit root_path
      sleep 1
      expect(page).not_to have_content 'Submitted Courses'
    end
  end

  describe 'visiting the None cohort' do
    it 'should see unsubmitted courses' do
      visit '/courses?cohort=none'
      sleep 1
      expect(page).to have_content 'Unsubmitted Courses'
      expect(page).to have_content 'My Unsubmitted Course'
    end
  end

  after do
    logout
    Capybara.use_default_driver
  end
end
