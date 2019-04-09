# frozen_string_literal: true

class EmailProcessor
  def initialize(email)
    @email = email
  end

  def process
    recipient_emails = @email.to.pluck(:email)
    owner = User.find_by(greeter: true, email: recipient_emails)

    email = @email.from[:email]
    sender = User.find_by(email: email) if email
    course = sender.courses.last if sender

    body, reference_id = parse_body_and_reference_id
    content = body
    content += " #{from_signature(@email.from)}" if sender.blank?

    dispense_or_thread_ticket(content, course, owner, reference_id, sender)
  end

  private

  def from_signature(from)
    ''"

    From #{from[:full]}
    "''
  end

  def parse_body_and_reference_id
    reference = @email.raw_body.match('ref_(.*)_ref')
    reference_id = reference[1] if reference

    return [@email.body, reference_id]
  end

  def dispense_or_thread_ticket(content, course, owner, reference_id, sender)
    raise unless reference_id

    TicketDispenser::Dispenser.thread(
      content: content,
      reference_id: reference_id,
      sender_id: sender.id
    )
  rescue StandardError
    TicketDispenser::Dispenser.call(
      content: content,
      owner_id: owner&.id,
      project_id: course&.id,
      sender_id: sender&.id
    )
  end
end
