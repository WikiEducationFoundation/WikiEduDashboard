require 'rails_helper'

describe 'activity page', type: :feature, js: true do
  before do
    include Devise::TestHelpers, type: :feature
    Capybara.current_driver = :selenium
  end


  before :each do
    create(:cohort,
           id: 1,
           title: 'Fall 2015')

    if page.driver.is_a?(Capybara::Webkit::Driver)
      page.driver.allow_url 'fonts.googleapis.com'
      page.driver.allow_url 'maxcdn.bootstrapcdn.com'
      page.driver.allow_url 'cdn.ravenjs.com'
      # page.driver.block_unknown_urls  # suppress warnings
    end
    login_as(user, scope: :user)
    visit root_path
  end

  describe 'non-admins' do
    let(:user) { create(:user, id: 2) }
    it 'shouldn\'t be viewable by non-admins' do
      within '.container .home' do
        expect(page).not_to have_content 'Activity'
      end
    end
  end

  describe 'admins' do
    let(:user) { create(:admin,
                  id: 200,
                  wiki_token: 'foo',
                  wiki_secret: 'bar') }

    it 'should be viewable by admins' do
      within '.container .home' do
        expect(page).to have_content 'Activity'
      end
    end
  end
end

