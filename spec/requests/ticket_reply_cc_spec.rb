# frozen_string_literal: true

require 'rails_helper'

# Covers the TicketDispenser engine endpoint the reply form posts to. A reply
# carrying CC addresses used to 500 here: the engine turned the permitted
# `details` params into a HashWithIndifferentAccess, which the YAML-serialized
# `details` column cannot dump under safe_dump.
describe 'creating a ticket reply', type: :request do
  let(:admin) { create(:admin, email: 'admin@wikiedu.org') }
  let(:user) { create(:user, email: 'student@hello.edu') }
  let(:ticket) do
    TicketDispenser::Dispenser.call(content: 'hello', owner_id: admin.id, sender_id: user.id)
  end

  before { login_as admin }

  def post_reply(details)
    post '/td/tickets/replies', params: {
      content: '<p>Reply body.</p>',
      kind: TicketDispenser::Message::Kinds::REPLY,
      ticket_id: ticket.id,
      sender_id: admin.id,
      read: true,
      status: TicketDispenser::Ticket::Statuses::AWAITING_RESPONSE,
      **details
    }, as: :json
  end

  it 'stores CC addresses so the mailer can read them' do
    post_reply(details: { cc: [{ email: 'cc@example.com' }, { email: 'two@example.com' }] })

    expect(response.status).to eq(201)
    # Symbol keys all the way down: TicketNotificationMailer#carbon_copy reads
    # `details[:cc]` and then `entry[:email]` on each entry.
    expect(TicketDispenser::Message.last.details[:cc])
      .to eq([{ email: 'cc@example.com' }, { email: 'two@example.com' }])
  end

  it 'creates a reply with no CC addresses' do
    post_reply({})

    expect(response.status).to eq(201)
    expect(TicketDispenser::Message.last.details).to eq({})
  end
end
