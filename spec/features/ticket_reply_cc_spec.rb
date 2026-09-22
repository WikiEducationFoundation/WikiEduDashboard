# frozen_string_literal: true

require 'rails_helper'

describe 'replying to a ticket with a CC address', type: :feature, js: true do
  let(:course) { create(:course) }
  let(:admin) { create(:admin, email: 'spec@wikiedu.org') }

  before do
    login_as admin
    stub_token_request
    create(:courses_user, course:, user: admin,
                          role: CoursesUsers::Roles::WIKI_ED_STAFF_ROLE)
  end

  it 'sends the reply instead of failing to save it' do
    visit "/courses/#{course.slug}"
    click_button 'Get Help'
    click_button 'question about editing Wikipedia'
    fill_in 'message', with: 'I need some help with adding a photo to my article.'
    click_button 'Send'
    click_button 'Ok'

    click_link 'Admin'
    click_link 'Open Tickets: 1'
    click_link 'Show'

    within('form.tickets-reply') do
      find('button.plus').click
      fill_in 'cc', with: 'cc@example.com'
      find('.wysiwyg-editor__content').click
      find('.wysiwyg-editor__content').send_keys('Looping in a colleague.')
    end
    click_button 'Send Reply'

    # The CC details used to 500 on save, which surfaced here as a failure
    # notice and left the reply unsent.
    expect(page).to have_content 'Ticket is currently Awaiting Response'
    expect(page).not_to have_content 'Creation of message failed'
    # The CC line is uppercased by `text-transform`, which Capybara reflects.
    expect(page).to have_content(/cc@example\.com/i)
    expect(TicketDispenser::Message.last.details[:cc]).to eq([{ email: 'cc@example.com' }])
  end
end
