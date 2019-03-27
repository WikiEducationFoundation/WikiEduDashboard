# frozen_string_literal: true

class EmailProcessor
  def initialize(email)
    @email = email
  end

  def process
    recipient_emails = @email.to.pluck(:email)
    recipients = User.where(email: recipient_emails)

    owner = recipients.find do |recipient|
      SpecialUsers.wikipedia_experts.include?(recipient.username)
    end
    owner ||= SpecialUsers.wikipedia_experts.first

    sender = User.find_by(email: @email.from[:email])
    course = sender.courses.last if sender

    content = @email.body
    content += " #{from_signature(@email.from)}" if sender.blank?

    ticket = TicketDispenser::Ticket.create(owner: owner, course: course)
    TicketDispenser::Message.create(
      content: content,
      sender: sender,
      ticket: ticket
    )
  end

  private

  def from_signature(from)
    ''"

    From #{from[:full]}
    "''
  end
end
