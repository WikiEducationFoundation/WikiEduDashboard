# frozen_string_literal: true

require 'rails_helper'

describe 'Account requests', type: :feature, js: true do
  let(:course) { create(:course, end: 1.week.from_now, flags: { register_accounts: true }) }

  it 'lets an unregistered user request an account' do
    # pending 'This may fail on travis-ci if the IP range is blocked from account creation.'

    visit "/courses/#{course.slug}?enroll=#{course.passcode}"
    click_button 'Request an account'
    fill_in 'new_account_username', with: 'My Example Username 123'
    fill_in 'new_account_email', with: 'example@wikiedu.org'
    click_button 'Check username availability'
    click_button 'Request account'
    expect(page).to have_content 'Your request for an account has been submitted'

    # pass_pending_spec
  end
end
