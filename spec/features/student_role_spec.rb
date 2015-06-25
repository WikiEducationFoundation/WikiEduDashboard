require 'rails_helper'

describe 'Student users', type: :feature do
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
                  wiki_token: 'foo',
                  wiki_secret: 'bar')
    login_as(user, scope: :user)
    visit root_path
  end

  # TODO: enroll via action button

  describe 'enrolling by url', js: true do
    it 'should let students join a course' do
      # Stub out the posting of content to Wikipedia using the same protocol as
      # wiki_edits_spec.rb
      # rubocop:disable Metrics/LineLength
      fake_tokens = "{\"query\":{\"tokens\":{\"csrftoken\":\"myfaketoken+\\\\\"}}}"
      # rubocop:enable Metrics/LineLength
      stub_request(:get, /.*wikipedia.*/)
        .to_return(status: 200, body: fake_tokens, headers: {})
      stub_request(:post, /.*wikipedia.*/)
        .to_return(status: 200, body: 'success', headers: {})

      visit "/courses/#{Course.first.slug}/students/enroll/passcode"
      sleep 1
      visit "/courses/#{Course.first.slug}/students"
      expect(page).to have_content User.first.wiki_id
      # TODO: add assignments and reviews
      # TODO: remove assignments and reviews
    end
  end

  after do
    logout
    Capybara.use_default_driver
  end
end
