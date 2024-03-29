# frozen_string_literal: true

require 'rails_helper'

describe 'user authentication with oauth credentials', type: :feature do
  describe 'a user with invalid oauth credentials' do
    before do
      user = create(:user, wiki_token: 'invalid')
      login_as user
    end

    it 'gets logged out and see a message about the problem' do
      error_message = I18n.t('error.oauth_invalid')
      visit root_path
      expect(page).to have_content error_message
      expect(page).to have_content 'Log in'
    end
  end

  describe 'a user whose oauth credentials expire', type: :feature do
    let(:admin)  { create(:admin) }
    let(:course) { create(:course, end: 1.year.from_now, submitted: true) }

    it 'is logged out upon visiting a course' do
      stub_token_request_failure

      login_as admin
      visit "/courses/#{escaped_slug course.slug}"
      expect(page).to have_current_path(root_path)
      expect(page).to have_content 'Your Wikipedia authorization has expired'
    end
  end
end
