# frozen_string_literal: true

require 'rails_helper'
require Rails.root.join('lib/tickets/ticket_notification_emails')

describe TicketNotificationEmails do
  let(:owner) { create(:admin, email: 'admin@wikiedu.org') }
  let(:course) { create(:course) }
  let(:ticket) do
    TicketDispenser::Dispenser.call(content: 'Help!',
                                    project_id: course.id,
                                    owner_id: owner.id,
                                    sender_id: nil,
                                    details: {})
  end
  let(:ticket_two) do
    TicketDispenser::Dispenser.call(content: 'Help again!',
                                    project_id: nil,
                                    owner_id: nil,
                                    sender_id: nil,
                                    details: {})
  end

  context 'when there is 1 open ticket' do
    before do
      ticket.update(status: TicketDispenser::Ticket::Statuses::OPEN)
    end

    it 'emails the owner of the ticket' do
      expect { described_class.notify }.to change { ActionMailer::Base.deliveries.count }.by(1)
      last_email = ActionMailer::Base.deliveries.last
      expect(last_email.subject).to include('there is 1 open ticket')
    end
  end

  context 'when there is an unassigned ticket' do
    before do
      ticket.update(status: TicketDispenser::Ticket::Statuses::OPEN)
      ticket_two.update(status: TicketDispenser::Ticket::Statuses::OPEN)
    end

    it 'includes the unassigned ticket in the count' do
      expect { described_class.notify }.to change { ActionMailer::Base.deliveries.count }.by(1)
      last_email = ActionMailer::Base.deliveries.last
      expect(last_email.subject).to include('there are 2 open tickets')
    end
  end

  context 'when there are no open tickets' do
    before do
      ticket.update(status: TicketDispenser::Ticket::Statuses::RESOLVED)
    end

    it 'emails the ticket owner(s)' do
      expect { described_class.notify }.to change { ActionMailer::Base.deliveries.count }.by(0)
    end
  end
end
