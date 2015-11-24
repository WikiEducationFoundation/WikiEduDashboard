require 'rails_helper'

describe 'Student users', type: :feature, js: true do
  before do
    include Devise::TestHelpers, type: :feature
    Capybara.current_driver = :selenium
    page.driver.browser.manage.window.resize_to(1920, 1080)
  end

  before :each do
    create(:cohort,
           id: 1)
    create(:course,
           id: 10001,
           title: 'An Example Course',
           school: 'University',
           term: 'Term',
           slug: 'University/An_Example_Course_(Term)',
           submitted: 1,
           listed: true,
           passcode: 'passcode',
           start: '2015-01-01'.to_date,
           end: '2020-01-01'.to_date)
    create(:user,
           id: 100,
           wiki_id: 'Professor Sage')
    create(:courses_user,
           user_id: 100,
           course_id: 10001,
           role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
    create(:cohorts_course,
           cohort_id: 1,
           course_id: 10001)
    create(:user,
           id: 101,
           wiki_id: 'Classmate')
    create(:courses_user,
           id: 2,
           user_id: 101,
           course_id: 10001,
           role: CoursesUsers::Roles::STUDENT_ROLE)
    user = create(:user,
                  id: 200,
                  wiki_token: 'foo',
                  wiki_secret: 'bar')
    login_as(user, scope: :user)
  end

  describe 'logging out' do
    it 'should work' do
      visit "/courses/#{Course.first.slug}"
      expect(page).to have_content 'Log Out'
      expect(page).not_to have_content 'Login'
      find('a', text: 'Log Out').click
      expect(page).to have_content 'Login'
      expect(page).not_to have_content 'Log Out'
    end

    it 'should not cause problems if done twice' do
      visit "/courses/#{Course.first.slug}"
      find('a', text: 'Log Out').click
      sleep 1
      visit '/sign_out'
    end
  end

  describe 'enrolling and unenrolling by button' do
    it 'should join and leave a course' do
      stub_oauth_edit

      # click enroll button
      visit "/courses/#{Course.first.slug}"
      sleep 1
      first('button').click

      # enter passcode in alert popup to enroll
      prompt = page.driver.browser.switch_to.alert
      prompt.send_keys('passcode')
      prompt.accept

      visit "/courses/#{Course.first.slug}/students"
      sleep 1
      expect(first('tbody')).to have_content User.last.wiki_id

      # now unenroll
      visit "/courses/#{Course.first.slug}"
      sleep 1
      click_button 'Leave course'
      page.driver.browser.switch_to.alert.accept
      sleep 1

      visit "/courses/#{Course.first.slug}/students"
      sleep 1
      expect(first('tbody')).not_to have_content User.last.wiki_id
    end
  end

  describe 'enrolling by url' do
    it 'should join a course' do
      stub_oauth_edit

      visit "/courses/#{Course.first.slug}/enroll/passcode"
      sleep 1
      visit "/courses/#{Course.first.slug}/students"
      sleep 1
      expect(first('tbody')).to have_content User.last.wiki_id
      # Now try enrolling again, which shouldn't cause any errors
      visit "/courses/#{Course.first.slug}/enroll/passcode"
    end

    it 'should work even if a student is not logged in' do
      pending 'fixing the intermittent failures on travis-ci'

      OmniAuth.config.test_mode = true
      allow_any_instance_of(OmniAuth::Strategies::Mediawiki)
        .to receive(:callback_url).and_return('/users/auth/mediawiki/callback')
      OmniAuth.config.mock_auth[:mediawiki] = OmniAuth::AuthHash.new(
        provider: 'mediawiki',
        uid: '12345',
        info: { name: 'Ragesock' },
        credentials: { token: 'foo', secret: 'bar' }
      )
      stub_oauth_edit
      logout
      visit "/courses/#{Course.first.slug}/students"
      visit "/courses/#{Course.first.slug}/enroll/passcode"
      visit "/courses/#{Course.first.slug}/students"
      sleep 1
      expect(first('tbody')).to have_content 'Ragesock'
      fail 'this test passed — this time'
    end

    it 'should work even if a student has never logged in before' do
      pending 'fixing the intermittent failures on travis-ci'

      OmniAuth.config.test_mode = true
      allow_any_instance_of(OmniAuth::Strategies::Mediawiki)
        .to receive(:callback_url).and_return('/users/auth/mediawiki/callback')
      OmniAuth.config.mock_auth[:mediawiki] = OmniAuth::AuthHash.new(
        provider: 'mediawiki',
        uid: '123456',
        info: { name: 'Ragesoss' },
        credentials: { token: 'foo', secret: 'bar' }
      )
      allow(Wiki).to receive(:get_user_id).and_return(234567)
      stub_oauth_edit
      logout
      visit "/courses/#{Course.first.slug}/enroll/passcode"
      visit "/courses/#{Course.first.slug}/students"
      sleep 1
      expect(first('tbody')).to have_content 'Ragesoss'
      fail 'this test passed — this time'
    end

    it 'should not work if user is not persisted' do
      OmniAuth.config.test_mode = true
      allow_any_instance_of(OmniAuth::Strategies::Mediawiki)
        .to receive(:callback_url).and_return('/users/auth/mediawiki/callback')
      OmniAuth.config.mock_auth[:mediawiki] = OmniAuth::AuthHash.new(
        provider: 'mediawiki',
        uid: '123456',
        info: { name: 'Ragesoss' },
        credentials: { token: 'foo', secret: 'bar' }
      )
      allow(UserImporter).to receive(:from_omniauth).and_return(build(:user, id: 2345678))
      stub_oauth_edit
      logout
      visit "/courses/#{Course.first.slug}/enroll/passcode"
      visit "/courses/#{Course.first.slug}/students"
      sleep 1
      expect(first('tbody')).not_to have_content 'Ragesoss'
    end
  end

  describe 'adding an assigned article' do
    it 'should work' do
      stub_oauth_edit
      create(:courses_user,
             course_id: 10001,
             user_id: 200,
             role: CoursesUsers::Roles::STUDENT_ROLE)
      visit "/courses/#{Course.first.slug}/students"
      sleep 3

      # Add an assigned article
      first('button.border').click
      within('#users') { first('input').set('Selfie') }
      page.all('button.border')[1].click
      page.driver.browser.switch_to.alert.accept
      sleep 1
      page.all('button.border')[0].click
      sleep 1
      expect(page.all('tr.students')[1]).to have_content 'Selfie'
      expect(first('tr.students')).not_to have_content 'Selfie'
    end
  end

  describe 'adding a reviewed article' do
    it 'should work' do
      stub_oauth_edit
      create(:courses_user,
             course_id: 10001,
             user_id: 200,
             role: CoursesUsers::Roles::STUDENT_ROLE)
      visit "/courses/#{Course.first.slug}/students"
      sleep 3

      page.all('button.border')[1].click
      within('#users') { first('input').set('Self-portrait') }
      page.all('button.border')[2].click
      page.driver.browser.switch_to.alert.accept
      page.all('button.border')[1].click
      expect(page).to have_content 'Self-portrait'
    end
  end

  describe 'removing an assigned article' do
    it 'should work' do
      stub_oauth_edit
      create(:courses_user,
             course_id: 10001,
             user_id: 200,
             role: CoursesUsers::Roles::STUDENT_ROLE)
      create(:assignment,
             article_title: 'Selfie',
             course_id: 10001,
             user_id: 200,
             role: Assignment::Roles::ASSIGNED_ROLE)
      visit "/courses/#{Course.first.slug}/students"
      sleep 3

      # Remove the assignment
      page.all('button.border')[0].click
      page.all('button.border')[2].click
      page.driver.browser.switch_to.alert.accept
      page.all('button.border')[0].click
      visit "/courses/#{Course.first.slug}/students"
      sleep 1
      expect(page).not_to have_content 'Selfie'
    end
  end

  describe 'visiting the home page' do
    it 'should see their course' do
      create(:courses_user,
             course_id: 10001,
             user_id: 200,
             role: CoursesUsers::Roles::STUDENT_ROLE)

      visit '/'
      expect(page).to have_content 'Your Courses'
      user_courses = find('#user_courses')
      expect(user_courses).to have_content 'An Example Course'
    end
  end

  after do
    logout
    Capybara.use_default_driver
  end
end
