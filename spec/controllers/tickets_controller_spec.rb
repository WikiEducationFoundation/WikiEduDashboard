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
  let(:message) { ticket.messages.first }

  before do
    login_as admin
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

  describe '#notify' do
    it 'triggers an email reply' do
      expect(TicketNotificationMailer).to receive(:notify_of_message).and_call_original
      post '/tickets/notify', params: { message_id: message.id, sender_id: admin.id }
      expect(response.status).to eq(200)
    end

    it 'triggers an email reply even if there is no sender' do
      message.update(sender: nil, details: { sender_email: user.email })
      expect(TicketNotificationMailer).to receive(:notify_of_message).and_call_original
      post '/tickets/notify', params: { message_id: message.id, sender_id: admin.id }
      expect(response.status).to eq(200)
    end
  end
end
