# frozen_string_literal: true

class TicketNotificationMailerPreview < ActionMailer::Preview
  def message_to_student
    sender = User.new(username: 'admin',
                      real_name: 'Delano (Wiki Edu)',
                      permissions: User::Permissions::ADMIN)
    recipient = User.new(username: 'flanagan.hyder')
    TicketNotificationMailer.notify(
      course:, message:, recipient:,
      sender:, bcc_to_salesforce: false
    )
  end

  def message_to_instructor
    sender = User.new(username: 'flanagan.hyder')
    recipient = User.new(username: 'admin',
                         real_name: 'Delano (Wiki Edu)',
                         permissions: User::Permissions::ADMIN)
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
    content = %(
      <p>Hi there,</p>
      <p>Tabella et aspernatur verecundia comburo et averto addo abutor
      caelestis sed adduco. Similique argentum deduco crustulum solium utrum
      undique denique. Vesco surgo ex pauci aveho aperiam. Arx volutabrum
      canonicus quo addo theatrum arcesso cognatus cohors. Tepidus auris qui
      convoco ulterius bibo confugo.</p>
    )
    ticket = TicketDispenser::Ticket.first || TicketDispenser::Dispenser.call(
      content:,
      course:,
      owner: recipient(:admin),
      sender:
    )
    ticket.messages.last
  end
end
