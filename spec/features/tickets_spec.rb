# frozen_string_literal: true

require 'rails_helper'

describe 'ticket system', type: :feature, js: true do
  let(:course) { create(:course) }
  let(:admin) { create(:admin, email: 'spec@wikiedu.org') }

  before do
    login_as admin
    stub_token_request
    create(:courses_user, course:, user: admin,
                          role: CoursesUsers::Roles::WIKI_ED_STAFF_ROLE)
  end

  it 'creates a ticket from a help request and lets an admin reply' do
    # Make a ticket
    visit "/courses/#{course.slug}"
    click_button 'Get Help'
    click_link 'question about editing Wikipedia'
    fill_in 'message', with: 'I need some help with adding a photo to my article.'
    click_button 'Send'
    click_link 'Ok'

    # Find the ticket
    click_link 'Admin'
    click_link 'Open Tickets: 1'
    click_link 'Show'

    # Reply to the ticket
    within('form.tickets-reply') do
      find('.mce-content-body').click
      find('.mce-content-body').send_keys('Please review this training module.')
    end
    click_button 'Send Reply'
    expect(page).to have_content 'Ticket is currently Awaiting Response'

    # Add and delete a Note
    within('form.tickets-reply') do
      find('.mce-content-body').click
      find('.mce-content-body').send_keys('Note for staff')
    end
    click_button 'Create Note'
    find('img[alt="delete icon"]').click
    expect(page).to have_content 'Note Deleted Successfully'

    # Email the ticket owner
    click_button 'Email Ticket Owner'
    expect(page).to have_content 'Email was sent to the owner.'

    # Update the status
    within 'section.status' do
      find('input').set('Resolved')
      all('div', text: 'Resolved')[2].click
    end
    expect(page).to have_content 'Ticket is currently Resolved'

    # Delete the ticket
    accept_prompt do
      click_button 'Delete Ticket'
    end

    expect(page).to have_content 'No tickets'
  end
end
