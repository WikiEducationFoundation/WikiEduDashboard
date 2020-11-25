# frozen_string_literal: true

require 'rails_helper'

describe 'ticket system', type: :feature, js: true do
  let(:course) { create(:course) }
  let(:admin) { create(:admin, email: 'spec@wikiedu.org') }

  before do
    login_as admin
    stub_token_request
    create(:courses_user, course: course, user: admin,
                          role: CoursesUsers::Roles::WIKI_ED_STAFF_ROLE)
  end

  it 'creates a ticket from a help request and lets an admin reply' do
    pending 'This fails because of an controlled/uncontrolled input warning in GetHelpButton.'

    visit "/courses/#{course.slug}"
    click_button 'Get Help'
    click_link 'question about editing Wikipedia'
    fill_in 'message', with: 'I need some help with adding a photo to my article.'
    click_button 'Send'
    click_link 'Ok'
    click_link 'Admin'
    click_link 'Open Tickets: 1'
    click_link 'Show'
    within('form.tickets-reply') do
      find('.mce-content-body').click
      find('.mce-content-body').send_keys('Please review this training module.')
    end
    click_button 'Send Reply'
    expect(page).to have_content 'Ticket is currently Awaiting Response'
    pass_pending_spec
  end
end
