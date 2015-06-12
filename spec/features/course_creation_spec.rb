require 'rails_helper'

describe 'New course creation and editing', type: :feature do
  before do
    include Devise::TestHelpers, type: :feature
    # Capybara.current_driver = :selenium
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
      find('#course_create').click

      # expect there to be a course created
      # go through the wizard
      # expect there to be a timeline
    end
  end

  after do
    logout
  end
end
