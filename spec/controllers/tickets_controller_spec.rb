# frozen_string_literal: true

require 'rails_helper'

describe TicketsController, type: :request do
  let(:admin) { create(:admin, email: 'admin@wikiedu.org') }
  let(:user) { create(:user, email: 'student@hello.edu') }

  let(:ticket) do
    TicketDispenser::Dispenser.call(
      content: 'hello',
      owner_id: admin.id,
      sender_id: user.id
    )
  end
  let(:message) { ticket.messages.last }

  before do
    login_as admin
    TicketDispenser::Message.create(ticket: ticket, kind: TicketDispenser::Message::Kinds::NOTE,
      content: 'this is a note')
    TicketDispenser::Message.create(ticket: ticket, kind: TicketDispenser::Message::Kinds::REPLY,
      content: 'this is a reply')
  end

  describe '#dashboard' do
    it 'renders the main tickets dashboard URL' do
      get '/tickets/dashboard'
      expect(response.status).to eq(200)
      expect(response.body).to include("id='react_root'")
    end

    it 'renders a ticket show path' do
      get '/tickets/dashboard/1'
      expect(response.status).to eq(200)
      expect(response.body).to include("id='react_root'")
    end
  end

  describe '#reply' do
    it 'triggers an email reply' do
      expect(TicketNotificationMailer).to receive(:notify_of_message).and_call_original
      post '/tickets/reply', params: { message_id: message.id, sender_id: admin.id }
      expect(response.status).to eq(200)
    end

    it 'includes replies and excludes notes' do
      expect(TicketNotificationMailer).to receive(:notify_of_message).and_call_original
      post '/tickets/reply', params: { message_id: message.id, sender_id: admin.id }

      delivery = ActionMailer::Base.deliveries.first
      expect(delivery.text_part.body).not_to include('this is a note')
      expect(delivery.text_part.body).to include('this is a reply')
    end

    it 'triggers an email reply even if there is no sender' do
      message.update(sender: nil, details: { sender_email: user.email })
      expect(TicketNotificationMailer).to receive(:notify_of_message).and_call_original
      post '/tickets/reply', params: { message_id: message.id, sender_id: admin.id }
      expect(response.status).to eq(200)
    end

    it 'updates the message record when email delivery fails' do
      allow(TicketNotificationMailer).to receive(:notify_of_message).and_raise('failed')

      expect do
        post '/tickets/reply', params: { message_id: message.id, sender_id: admin.id }
      end.to raise_error('failed')

      expect(message.reload.details[:delivery_failed]).not_to be_nil
    end
  end

  describe '#notify_owner' do
    let(:recipient) { create(:admin, username: 'otheradmin', email: 'otheradmin@email.com') }
    let(:message) do
      TicketDispenser::Message.create(ticket: ticket, kind: TicketDispenser::Message::Kinds::NOTE,
                                      content: 'this is a note')
    end

    it 'includes notes and replies' do
      ticket.update(owner: recipient)

      expect(TicketNotificationMailer).to receive(:notify_of_message).and_call_original
      params = { message_id: message.id, sender_id: admin.id }
      post '/tickets/notify_owner', params: params
      expect(response.status).to eq(200)

      delivery = ActionMailer::Base.deliveries.first
      expect(delivery.to).to include(recipient.email)
      expect(delivery.from).to include(admin.email)
      expect(delivery.html_part.body).to include('this is a note')
      expect(delivery.text_part.body).to include('this is a reply')
    end
  end
end
