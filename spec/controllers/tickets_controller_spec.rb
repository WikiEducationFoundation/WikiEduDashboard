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
  let(:unknown_sender_ticket) do
    TicketDispenser::Dispenser.call(
      content: 'hello',
      owner_id: admin.id,
      details: {
        subject: 'cool story',
        sender_email: 'hello@coolstory.com'
      }
    )
  end
  let(:message) { ticket.messages.last }

  before do
    login_as admin
    TicketDispenser::Message.create(ticket:, kind: TicketDispenser::Message::Kinds::NOTE,
                                    content: 'this is a note')
    TicketDispenser::Message.create(ticket:, kind: TicketDispenser::Message::Kinds::REPLY,
                                    content: 'this is a reply')
    TicketDispenser::Message.create(
      ticket: unknown_sender_ticket,
      kind: TicketDispenser::Message::Kinds::REPLY,
      content: 'this is also a reply'
    )
  end

  describe '#dashboard' do
    it 'renders the main tickets dashboard URL' do
      get '/tickets/dashboard'
      expect(response.status).to eq(200)
      expect(response.body).to include("id='react_root'")
    end

    it 'renders a ticket show path' do
      get "/tickets/dashboard/#{ticket.id}"
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

    it 'optionally BCC\'s Salesforce' do
      expect(TicketNotificationMailer).to receive(:notify_of_message).and_call_original
      params = { message_id: message.id, sender_id: admin.id, bcc_to_salesforce: true }
      post '/tickets/reply', params: params

      delivery = ActionMailer::Base.deliveries.first
      expect(delivery.bcc).to include(ENV['SALESFORCE_BCC_EMAIL'])
    end

    it 'does not set BCC if bcc_to_salesforce param is not included' do
      expect(TicketNotificationMailer).to receive(:notify_of_message).and_call_original
      params = { message_id: message.id, sender_id: admin.id }
      post '/tickets/reply', params: params

      delivery = ActionMailer::Base.deliveries.first
      expect(delivery.bcc).not_to include(ENV['SALESFORCE_BCC_EMAIL'])
    end

    it 'works even when user is not known' do
      expect(TicketNotificationMailer).to receive(:notify_of_message).and_call_original
      params = { message_id: unknown_sender_ticket.messages.first.id, sender_id: admin.id }
      post '/tickets/reply', params: params

      delivery = ActionMailer::Base.deliveries.first
      expect(delivery.to).to include('hello@coolstory.com')
    end
  end

  describe '#notify_owner' do
    let(:recipient) { create(:admin, username: 'otheradmin', email: 'otheradmin@email.com') }
    let(:message) do
      TicketDispenser::Message.create(ticket:, kind: TicketDispenser::Message::Kinds::NOTE,
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
