# frozen_string_literal: true

require 'rails_helper'

describe 'ticket message XSS protection', type: :feature, js: true do
  let(:admin) { create(:admin, email: 'spec@wikiedu.org') }
  let(:course) { create(:course) }

  before do
    login_as admin
    stub_token_request
  end

  it 'does not render HTML tags in message content' do
    xss_payload = 'hello <img src=x onerror=document.title="XSS"> world'

    ticket = TicketDispenser::Dispenser.call(
      content: xss_payload,
      owner_id: admin.id,
      project_id: course.id,
      details: { subject: 'Test ticket' }
    )

    visit "/tickets/dashboard/#{ticket.id}"
    # Wait for the React component to render the safe text
    expect(page).to have_content('hello')

    # The malicious HTML should not execute — page title should remain unchanged
    expect(page.title).not_to eq('XSS')

    # The img tag should not be rendered as an element
    expect(page).not_to have_css('.message-body img')
  end
end
