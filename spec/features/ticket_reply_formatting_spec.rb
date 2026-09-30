# frozen_string_literal: true

require 'rails_helper'

describe 'ticket reply formatting', type: :feature, js: true do
  let(:course) { create(:course) }
  let(:admin) { create(:admin, email: 'spec@wikiedu.org') }

  before do
    login_as admin
    stub_token_request
    create(:courses_user, course:, user: admin,
                          role: CoursesUsers::Roles::WIKI_ED_STAFF_ROLE)
  end

  it 'keeps the paragraph breaks of a reply composed in the wysiwyg editor' do
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
      find('.wysiwyg-editor__content').click
      find('.wysiwyg-editor__content').send_keys('First paragraph.', :enter, :enter,
                                                 'Second paragraph.')
    end
    click_button 'Send Reply'
    expect(page).to have_content 'Ticket is currently Awaiting Response'

    # The two paragraphs must stay separate blocks. Before the reply body
    # rendered its HTML, the paragraph tags were stripped and the text ran
    # together as 'First paragraph.Second paragraph.'
    body = all('.message-body').find { |div| div.text.include?('First paragraph.') }
    expect(body.text).not_to include 'First paragraph.Second paragraph.'
    expect(body).to have_selector 'p', text: 'First paragraph.'
    expect(body).to have_selector 'p', text: 'Second paragraph.'
  end

  it 'keeps the newlines of a plain text message that has no markup' do
    ticket = TicketDispenser::Dispenser.call(
      content: "First line.\n\nSecond line.",
      owner_id: admin.id,
      project_id: course.id,
      sender_id: admin.id,
      details: { subject: 'Plain text reply' }
    )

    visit "/tickets/dashboard/#{ticket.id}"

    body = all('.message-body').find { |div| div.text.include?('First line.') }
    expect(body[:class]).to include 'plaintext'
    expect(body.text).not_to include 'First line.Second line.'
  end
end
