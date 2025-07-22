# frozen_string_literal: true

class TicketNotificationMailerPreview < ActionMailer::Preview
  def message_to_student
    sender = User.new(username: 'admin',
                      real_name: 'Delano (Wiki Edu)',
                      permissions: User::Permissions::ADMIN,
                      email: 'admin@mail.com')
    recipient = User.new(username: 'flanagan.hyder', email: 'recipient@mail.com')
    TicketNotificationMailer.notify(
      course:, message:, recipient:,
      sender:, bcc_to_salesforce: false
    )
  end

  def message_to_instructor
    sender = User.new(username: 'flanagan.hyder', email: 'student@mail.com')
    recipient = User.new(username: 'admin',
                         real_name: 'Delano (Wiki Edu)',
                         permissions: User::Permissions::ADMIN,
                         email: 'admin@mail.com')
    TicketNotificationMailer.notify(
      course:, message:, recipient:,
      sender:, bcc_to_salesforce: false
    )
  end

  def open_tickets_notification
    owner = User.admin.first
    tickets = TicketDispenser::Ticket.first(20)
    TicketNotificationMailer.open_tickets_notify(
      owner:,
      tickets:
    )
  end

  private

  def course
    Course.new(slug: 'course/title', title: 'My Course')
  end

  def message
    message1 = OpenStruct.new(
      reply?: 0,
      content: 'I cannot log to this course ...',
      details: { cc: [{ email: 'other@email.com' }], delivered: Time.zone.now },
      created_at: Time.zone.now
    )
    message2 = OpenStruct.new(
      reply?: 0,
      content: 'Did you properly register ?',
      details: { cc: [{ email: 'other@email.com' }], delivered: Time.zone.now },
      created_at: Time.zone.now
    )
    ticket = OpenStruct.new(messages: [message1, message2])
    message1.ticket = ticket
    message2.ticket = ticket
    message2
  end
end
