# frozen_string_literal: true

require 'rails_helper'

describe 'TicketDispenser CSRF', type: :request do
  let(:user) { create(:user, username: 'SignedInUser') }
  let(:admin) { create(:admin) }

  describe 'TicketDispenser engine writes' do
    let(:ticket) { TicketDispenser::Ticket.create!(project: create(:course), owner: admin, status: 0) }

    around do |example|
      ActionController::Base.allow_forgery_protection = true
      example.run
    ensure
      ActionController::Base.allow_forgery_protection = false
    end

    it 'are refused without a CSRF token' do
      login_as admin
      delete "/td/tickets/#{ticket.id}", params: { id: ticket.id }
      expect(TicketDispenser::Ticket.exists?(ticket.id)).to be true
    end

    it 'are accepted with the token from the tickets page' do
      login_as admin
      get '/tickets/dashboard'
      token = response.body[/<meta name="csrf-token" content="([^"]+)"/, 1]
      delete "/td/tickets/#{ticket.id}", params: { id: ticket.id },
                                         headers: { 'X-CSRF-Token' => token }
      expect(TicketDispenser::Ticket.exists?(ticket.id)).to be false
    end
  end
end
