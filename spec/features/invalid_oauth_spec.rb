require 'rails_helper'

describe 'a user with invalid oauth credentials', type: :feature do
  before do
    user = create(:user, wiki_token: 'invalid')
    login_as user
    create(:cohort, slug: Figaro.env.default_cohort)
  end

  before :each do
    if page.driver.is_a?(Capybara::Webkit::Driver)
      page.driver.allow_url 'fonts.googleapis.com'
      page.driver.allow_url 'maxcdn.bootstrapcdn.com'
      page.driver.allow_url 'cdn.ravenjs.com'
      # page.driver.block_unknown_urls  # suppress warnings
    end
  end

  it 'should get logged out and see a message about the problem' do
    error_message = I18n.t('error.oauth_invalid')
    visit root_path
    expect(page).to have_content error_message
    expect(page).to have_content 'Login'
  end
end
