require 'rails_helper'

def stub_oauth_edit
  # Stub out the posting of content to Wikipedia using the same protocol as
  # wiki_edits_spec.rb
  # rubocop:disable Metrics/LineLength
  fake_tokens = "{\"query\":{\"tokens\":{\"csrftoken\":\"myfaketoken+\\\\\"}}}"
  # rubocop:enable Metrics/LineLength
  stub_request(:get, /.*wikipedia.*/)
    .to_return(status: 200, body: fake_tokens, headers: {})
  stub_request(:post, /.*wikipedia.*/)
    .to_return(status: 200, body: 'success', headers: {})
end

describe 'Student users', type: :feature, js: true do
  before do
    include Devise::TestHelpers, type: :feature
    Capybara.current_driver = :selenium
  end

  before :each do
    create(:cohort,
           id: 1)
    create(:course,
           id: 10001,
           slug: 'University/Course_(Term)',
           submitted: 1,
           listed: true,
           passcode: 'passcode',
           start: '2015-01-01'.to_date,
           end: '2020-01-01'.to_date)
    create(:cohorts_course,
           cohort_id: 1,
           course_id: 10001)
    user = create(:user,
                  id: 1,
                  wiki_token: 'foo',
                  wiki_secret: 'bar')
    login_as(user, scope: :user)
    visit root_path
  end

  describe 'enrolling and unenrolling by button' do
    it 'should join a course' do
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
      expect(first('tbody')).to have_content User.first.wiki_id

      # now unenroll
      visit "/courses/#{Course.first.slug}"
      page.all('button').last.click
      page.driver.browser.switch_to.alert.accept

      visit "/courses/#{Course.first.slug}/students"
      expect(first('tbody')).not_to have_content User.first.wiki_id
    end
  end

  describe 'enrolling by url' do
    it 'should join a course' do
      stub_oauth_edit

      visit "/courses/#{Course.first.slug}/students/enroll/passcode"
      visit "/courses/#{Course.first.slug}/students"
      expect(first('tbody')).to have_content User.first.wiki_id
    end
  end

  describe 'adding and removing assignments' do
    it 'should work' do
      stub_oauth_edit
      create(:courses_user,
             course_id: 10001,
             user_id: 1,
             role: 0)
      visit "/courses/#{Course.first.slug}/students"
      sleep 1

      # Add an assigned article
      first('button.border').click
      first('input').set('Selfie')
      page.all('button.border')[1].click
      page.driver.browser.switch_to.alert.accept
      page.all('button.border')[0].click
      expect(page).to have_content 'Selfie'

      # TODO: Work around mysql errors for the rest of this spec
      # # Add a reviewed article
      # page.all('button.border')[1].click
      # first('input').set('Self-portrait')
      # page.all('button.border')[2].click
      # page.driver.browser.switch_to.alert.accept
      # page.all('button.border')[1].click
      # expect(page).to have_content 'Self-portrait'

      # # Remove the assignment
      # page.all('button.border')[0].click
      # page.all('button.border')[2].click
      # sleep 3
      # page.driver.browser.switch_to.alert.accept
      # page.all('button.border')[0].click
      # sleep 3
      # visit "/courses/#{Course.first.slug}/students"
      # expect(page).not_to have_content 'Selfie'
    end
  end
  after do
    logout
    Capybara.use_default_driver
  end
end
