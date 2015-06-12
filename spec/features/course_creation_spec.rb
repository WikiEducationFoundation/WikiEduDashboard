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
    it 'should display "Create course" button' do
      find("a[href='/course_creator']").click
      expect(page).to have_content 'Create a New Course'
    end
  end
end
