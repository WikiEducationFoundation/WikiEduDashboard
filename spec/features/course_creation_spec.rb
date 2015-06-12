require 'rails_helper'

describe 'New course creation and editing', type: :feature do
  before do
    include Devise::TestHelpers, type: :feature
    Capybara.current_driver = :selenium
  end

  before :each do
    if page.driver.is_a?(Capybara::Webkit::Driver)
      page.driver.allow_url 'fonts.googleapis.com'
      page.driver.allow_url 'maxcdn.bootstrapcdn.com'
      # page.driver.block_unknown_urls  # suppress warnings
    end
    create(:cohort)
    user = create(:user)
    login_as(user, scope: :user)
    visit root_path
  end

  describe 'new course workflow', js: true do
    it 'should allow the user to create a course' do
      find("a[href='/course_creator']").click
      expect(page).to have_content 'Create a New Course'
      find('#course_title').set('My awesome new cour$e: Foo 101')

      # If we click before filling out all require fields, only the invalid
      # fields get restyled to indicate the problem.
      find('#course_create').click
      expect(find('#course_title')['class']).not_to eq('invalid')
      expect(find('#course_school')['class']).to eq('invalid')
      expect(find('#course_term')['class']).to eq('invalid')

      # Now we fill out all the fields and continue.
      find('#course_school').set('University of Eastern Wikipedia')
      find('#course_term').set('Fall 2015')
      find('#course_subject').set('Advanced Studies')
      find('#course_expected_students').set('500')
      find('textarea').set('In this course, we study things.')
      # TODO: test the date picker

      # Stub out the posting of content to Wikipedia using the same protocol as
      # wiki_edits_spec.rb
      # rubocop:disable Metrics/LineLength
      fake_tokens = "{\"query\":{\"tokens\":{\"csrftoken\":\"myfaketoken+\\\\\"}}}"
      # rubocop:enable Metrics/LineLength
      stub_request(:get, /.*wikipedia.*/)
        .to_return(status: 200, body: fake_tokens, headers: {})
      stub_request(:post, /.*wikipedia.*/)
        .to_return(status: 200, body: 'success', headers: {})

      # This click should create the course and start the wizard
      find('#course_create').click

      # Go through the wizard, checking necessary options.
      sleep 3
      page.all('.wizard__option__description')[1].click
      sleep 1
      first('.button.dark').click
      sleep 1
      page.all('div.wizard__option__checkbox')[1].click
      page.all('div.wizard__option__checkbox')[3].click
      sleep 1
      first('.button.dark').click

      # Now go back and edit choices
      sleep 1
      page.all('div.wizard__option.summary')[1].click
      sleep 1
      page.all('div.wizard__option__checkbox')[3].click
      page.all('div.wizard__option__checkbox')[2].click
      page.all('div.wizard__option__checkbox')[4].click
      sleep 1
      first('.button.dark').click
      sleep 1
      first('.button.dark').click

      # Now we're back at the timeline, having completed the wizard.
      sleep 1
      expect(page).to have_content 'Week 1'
      expect(page).to have_content 'Week 2'

      # Click edit and then cancel
      first('.button.dark').click
      sleep 1
      first('.button').click

      # Click edit and then make a change and save it.
      sleep 1
      first('.button.dark').click
      first('input').set('The first week')
      sleep 1
      first('.button.dark').click
      sleep 1
      expect(page).to have_content 'The first week'

      # Click edit, delete some stuff, and save it.
      first('.button.dark').click
      sleep 1
      page.all('.button.danger')[1].click
      sleep 1
      page.all('.button.danger')[0].click
      sleep 1
      first('.button.dark').click
      sleep 1
      expect(page).not_to have_content 'The first week'
    end
  end

  after do
    logout
    Capybara.use_default_driver
  end
end
