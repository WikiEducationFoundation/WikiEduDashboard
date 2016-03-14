require 'rails_helper'

describe 'Surveys', type: :feature, js: true do
  before do
    include Devise::TestHelpers, type: :feature
    Capybara.current_driver = :selenium
    page.current_window.resize_to(1920, 1080)
  end

  before :each do
    user = create(:admin,
                  id: 200,
                  wiki_token: 'foo',
                  wiki_secret: 'bar')
    login_as(user, scope: :user)
  end

  describe 'Admin Survey Index' do
    it 'Lists all surveys' do
      visit '/surveys';
      click_link('New Survey')
      expect(page.find("h1")).to have_content("New Survey")
      fill_in('survey[name]', :with => 'My New Survey')
      click_button('Create Survey')
      expect(page).to have_content("My New Survey")
    end
  end

  after do
    logout
    Capybara.use_default_driver
  end
end