require 'rails_helper'

describe 'a user with invalid oauth credentials', type: :feature do
  before do
    user = create(:user, wiki_token: 'invalid')
    login_as user
    create(:cohort, slug: Figaro.env.default_cohort)
  end

  it 'should get logged out and see a message about the problem' do
    error_message = I18n.t('error.oauth_invalid')
    visit root_path
    expect(page).to have_content error_message
    expect(page).to have_content 'Log in'
  end
end
