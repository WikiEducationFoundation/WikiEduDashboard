# frozen_string_literal: true

class EmailProcessor
  def initialize(email)
    @email = email
  end

  def process
    recipient_email = @email.from.email
    recipient = User.find_by(email: recipient_email)

    experts = SpecialUsers.wikipedia_experts
    owner = recipient && experts.include?(recipient.username) ? recipient : experts.first

    sender = User.find_by(email: @email.from[:email])
    content = @email.body

    course = nil
    if sender.blank?
      content += " #{from_signature(@email.from)}"
    else
      course = sender.courses.last
    end

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
