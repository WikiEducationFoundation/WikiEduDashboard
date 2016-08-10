require 'rails_helper'

describe 'Student users', type: :feature, js: true do
  before do
    include Devise::TestHelpers, type: :feature
    Capybara.current_driver = :poltergeist
    page.current_window.resize_to(1920, 1080)
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
           username: 'Professor Sage')
    create(:courses_user,
           user_id: 100,
           course_id: 10001,
           role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
    create(:cohorts_course,
           cohort_id: 1,
           course_id: 10001)
    create(:user,
           id: 101,
           username: 'Classmate')
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

  describe 'clicking log out' do
    it 'logs them out' do
      visit "/courses/#{Course.first.slug}"
      expect(page).to have_content 'Log out'
      expect(page).not_to have_content 'Log in'
      find('a', text: 'Log out').click
      expect(page).to have_content 'Log in'
      expect(page).not_to have_content 'Log out'
    end

    it 'does not cause problems if done twice' do
      visit "/courses/#{Course.first.slug}"
      find('a', text: 'Log out').click
      sleep 1
      visit '/sign_out'
    end
  end

  describe 'enrolling and unenrolling by button' do
    it 'joins and leaves a course' do
      stub_oauth_edit

      # click enroll button, enter passcode in alert popup to enroll
      visit "/courses/#{Course.first.slug}"

      expect(page).to have_content 'An Example Course'

      accept_prompt(with: 'passcode') do
        click_button 'Join course'
      end

      sleep 3

      visit "/courses/#{Course.first.slug}/students"
      expect(find('tbody', match: :first)).to have_content User.last.username

      # now unenroll
      visit "/courses/#{Course.first.slug}"

      expect(page).to have_content 'An Example Course'

      accept_confirm do
        click_button 'Leave course'
      end

      sleep 3

      visit "/courses/#{Course.first.slug}/students"
      expect(find('tbody', match: :first)).not_to have_content User.last.username
    end

    it 'redirects to an error page if passcode is incorrect' do
      visit "/courses/#{Course.first.slug}"
      sleep 1
      accept_prompt(with: 'wrong_passcode') do
        click_button 'Join course'
      end
      expect(page).to have_content 'Incorrect passcode'
      sleep 5
    end
  end

  describe 'visiting the ?enroll=passcode url' do
    it 'joins a course' do
      stub_oauth_edit

      visit "/courses/#{Course.first.slug}?enroll=passcode"
      expect(page).to have_content User.last.username
      click_link 'Join'
      sleep 1
      visit "/courses/#{Course.first.slug}/students"
      expect(find('tbody', match: :first)).to have_content User.last.username
      # Now try enrolling again, which shouldn't cause any errors
      visit "/courses/#{Course.first.slug}/enroll/passcode"
    end

    it 'works even if a student is not logged in' do
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
      visit "/courses/#{Course.first.slug}?enroll=passcode"
      first(:link, 'Log in with Wikipedia').click
      expect(page).to have_content 'Ragesock'
      click_link 'Join'
      sleep 1
      visit "/courses/#{Course.first.slug}/students"
      expect(find('tbody', match: :first)).to have_content 'Ragesock'

      puts 'PASSED'
      raise 'this test passed — this time'
    end

    it 'works even if a student has never logged in before' do
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
      allow_any_instance_of(WikiApi).to receive(:get_user_id).and_return(234567)
      stub_oauth_edit
      logout
      visit "/courses/#{Course.first.slug}?enroll=passcode"
      first(:link, 'Log in with Wikipedia').click
      expect(find('.intro')).to have_content 'Ragesoss'
      click_link 'Start'
      fill_in 'name', with: 'Sage Ross'
      fill_in 'email', with: 'sage@example.com'
      click_button 'Submit'
      sleep 1
      click_link 'Finish'
      click_link 'Join'
      sleep 1
      visit "/courses/#{Course.first.slug}/students"
      expect(find('tbody', match: :first)).to have_content 'Ragesoss'

      puts 'PASSED'
      raise 'this test passed — this time'
    end

    it 'does not work if user is not persisted' do
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

    it 'redirects to a login error page if login fails' do
      logout
      OmniAuth.config.test_mode = true
      allow_any_instance_of(OmniAuth::Strategies::Mediawiki)
        .to receive(:callback_url).and_return('/users/auth/mediawiki/callback')
      OmniAuth.config.mock_auth[:mediawiki] = OmniAuth::AuthHash.new(
        extra: { raw_info: { login_failed: true } }
      )
      visit "/courses/#{Course.first.slug}/enroll/passcode"
      expect(page).to have_content 'Login Error'
    end
  end

  describe 'inputing an assigned article' do
    it 'assigns the article' do
      stub_raw_action
      stub_oauth_edit
      stub_info_query
      create(:courses_user,
             course_id: 10001,
             user_id: 200,
             role: CoursesUsers::Roles::STUDENT_ROLE)
      visit "/courses/#{Course.first.slug}/students"
      sleep 2

      # Add an assigned article
      find('button.border', match: :first).click
      within('#users') { find('input', match: :first).set('Selfie') }
      accept_confirm do
        page.all('button.border')[1].click
      end
      sleep 1
      page.all('button.border')[0].click
      sleep 1
      expect(page.all('tr.students')[1]).to have_content 'Selfie'
      expect(find('tr.students', match: :first)).not_to have_content 'Selfie'
    end
  end

  describe 'inputing a reviewed article' do
    it 'assigns the review' do
      stub_raw_action
      stub_oauth_edit
      stub_info_query
      create(:courses_user,
             course_id: 10001,
             user_id: 200,
             role: CoursesUsers::Roles::STUDENT_ROLE)
      visit "/courses/#{Course.first.slug}/students"
      sleep 3

      page.all('button.border')[1].click
      within('#users') { find('input', match: :first).set('Self-portrait') }
      accept_confirm do
        page.all('button.border')[2].click
      end
      page.all('button.border')[1].click
      expect(page).to have_content 'Self-portrait'
    end
  end

  describe 'clicking remove for an assigned article' do
    it 'removes the assignment' do
      stub_raw_action
      stub_oauth_edit
      stub_info_query
      create(:courses_user,
             course_id: 10001,
             user_id: 200,
             role: CoursesUsers::Roles::STUDENT_ROLE)
      create(:assignment,
             article_title: 'Selfie',
             course_id: 10001,
             user_id: 200,
             article_id: nil,
             role: Assignment::Roles::ASSIGNED_ROLE)
      visit "/courses/#{Course.first.slug}/students"
      sleep 3

      # Remove the assignment
      page.all('button.border')[0].click
      accept_confirm do
        page.all('button.border')[2].click
      end
      page.all('button.border')[0].click
      visit "/courses/#{Course.first.slug}/students"
      sleep 1
      expect(page).not_to have_content 'Selfie'
    end
  end

  describe 'visiting the dashboard homepage' do
    it 'sees their course' do
      create(:courses_user,
             course_id: 10001,
             user_id: 200,
             role: CoursesUsers::Roles::STUDENT_ROLE)

      visit root_path
      expect(page).to have_content 'My Dashboard'
      expect(page).to have_content 'An Example Course'
    end
  end

  after do
    logout
    Capybara.use_default_driver
  end
end
