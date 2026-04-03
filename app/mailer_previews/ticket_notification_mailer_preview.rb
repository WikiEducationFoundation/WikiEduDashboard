# frozen_string_literal: true

class TicketNotificationMailerPreview < ActionMailer::Preview
  DESCRIPTION = 'Sent when a support ticket message is exchanged, or to summarize open tickets.'
  METHOD_DESCRIPTIONS = {
    message_to_student: 'Reply from a Wiki Ed admin to a student who submitted a help ticket',
    message_to_instructor: 'Reply from a student or instructor to a Wiki Ed admin',
    open_tickets_notification: 'Daily digest listing all currently open tickets for the owner'
  }.freeze
  METHOD_RECIPIENTS = {
    message_to_student: 'student',
    message_to_instructor: 'staff',
    open_tickets_notification: 'staff'
  }.freeze

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
    owner = User.new(username: 'Ian (Wiki Ed)', real_name: 'Ian (Wiki Ed)',
                     email: 'ian@example.com', permissions: User::Permissions::ADMIN)
    TicketNotificationMailer.open_tickets_notify(owner:, tickets: mock_tickets)
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

  def mock_tickets
    3.times.map do |i|
      OpenStruct.new(
        id: i + 1,
        subject: "Help request #{i + 1}: student enrollment issue",
        sender: { username: 'Some_Student', real_name: 'Some Student',
                  email: 'student@example.com' },
        project: nil,
        created_at: (i + 1).weeks.ago
      )
    end
  end
end
