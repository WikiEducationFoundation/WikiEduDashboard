# frozen_string_literal: true

require 'rails_helper'

describe 'Account requests', type: :feature, js: true do
  let(:course) { create(:course, end: 7.days.from_now) }
  let(:instructor) { create(:user) }

  before do
    allow(Features).to receive(:wiki_ed?).and_return(false)
    course.campaigns << Campaign.first
    JoinCourse.new(course:, user: instructor,
                   role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
    stub_token_request
  end

  it 'can be enabled by the course facilitator' do
    login_as(instructor)
    visit "/courses/#{course.slug}"
    click_button 'Enable account requests'
    click_button 'OK'
    expect(page).to have_content('Account request generation enabled')
  end

  it 'can be used by logged out users via the enroll link' do
    pending 'Checking username availibility will not work in CI because of IP range blocks'

    course.update(flags: { register_accounts: true })
    visit "/courses/#{course.slug}?enroll=#{course.passcode}"
    click_button 'Request an account'
    fill_in 'new_account_username', with: 'Wiki Education Dashboard Tester'
    fill_in 'new_account_email', with: 'tester@wikiedu.org'
    click_button 'Check username availability'
    click_button 'Request account'
    expect(page).to have_content('Your request for an account has been submitted')

    pass_pending_spec
  end
end
