# frozen_string_literal: true

class TicketNotificationMailerPreview < ActionMailer::Preview
  def message_to_student
    TicketNotificationMailer.notify(course, message, recipient, sender)
  end

  def message_to_instructor
    TicketNotificationMailer.notify(course, message, recipient(:admin), sender)
  end

  private

  def course
    Course.new(slug: 'course/title', title: 'My Course')
  end

  def recipient(admin=false)
    User.new(username: 'janesmith',
             real_name: 'Jane Smith',
             permissions: admin ? User::Permissions::ADMIN : User::Permissions::NONE)
  end

  def sender
    User.new(username: 'senderjoed')
  end

  def message
    content = %(
      <p>Hello there,</p>
      <p>I have a question about using the dashboard...</p>
    )
    ticket = TicketDispenser::Ticket.first || TicketDispenser::Dispenser.call(
      content: content,
      course: course,
      owner: recipient(:admin),
      sender: sender
    )
    ticket.messages.last
  end
end
