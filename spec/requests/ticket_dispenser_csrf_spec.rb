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
  end
end
