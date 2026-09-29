# frozen_string_literal: true

require 'rails_helper'

# The shared refusal page (errors/unauthorized) is rendered for every
# not-signed-in, not-permitted and not-admin refusal. Logging in only helps
# with the first of those, so the button should appear only then.
describe 'the unauthorized page', type: :feature do
  let(:user) { create(:user) }

  context 'for a signed-in user who lacks the role' do
    before { login_as(user, scope: :user) }
    after { logout }

    it 'explains the refusal without offering to log in' do
      visit '/course_flags'
      expect(page).to have_content 'Only administrators may do that.'
      expect(page).not_to have_link 'Log in with Wikipedia'
      expect(page).to have_link 'Home', href: '/'
    end
  end

  context 'when signed out' do
    it 'offers to log in' do
      visit '/course_flags'
      expect(page).to have_content 'Please sign in.'
      expect(page).to have_link 'Log in with Wikipedia'
    end
  end
end
