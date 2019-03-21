# frozen_string_literal: true

require 'rails_helper'

describe TicketsController, type: :request do
  let(:admin) { create(:admin) }
  let(:course) { create(:course) }
  
  before do
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(admin)
  end

  describe '#index' do
    it 'should return an empty json response of all tickets' do
      get "/tickets"
      expected = { tickets: [] }.to_json
      expect(response.body).to eq(expected)
    end

    it 'should return tickets if there are any' do
      Ticket.create(owner: admin, course: course, status: 0)
      
      get "/tickets"
      tickets = JSON.parse(response.body)['tickets']
      expect(tickets.length).to equal(1)

      ticket = tickets[0]
      expect(ticket['course_id']).to equal(course.id)
      expect(ticket['owner_id']).to equal(admin.id)
      expect(ticket['status']).to equal(0)
      expect(ticket['messages']).to eq([])
    end

    let(:user) { create(:user) }
    it 'should return messages embedded in tickets if there are any' do
      ticket = Ticket.create(owner: admin, course: course, status: 0)
      Message.create(ticket: ticket, sender: user, content: 'Hello')

      get "/tickets"
      tickets = JSON.parse(response.body)['tickets']
      expect(tickets.length).to equal(1)

      ticket = tickets[0]
      messages = ticket['messages']
      expect(messages.length).to equal(1)

      message = messages[0]
      expect(message['sender_id']).to equal(user.id)
      expect(message['read']).to equal(false)
    end
  end
end