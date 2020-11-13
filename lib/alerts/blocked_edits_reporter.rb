# frozen_string_literal: true

class BlockedEditsReporter
  def self.create_alerts_for_blocked_edits(user, response_data)
    new.create_alert(user, response_data)
  end

  def create_alert(user, response_data)
    return if alert_already_exists?
    @alert = Alert.create!(type: 'BlockedEditsAlert',
                           user_id: user.id,
                           target_user_id: technical_help_staff&.id,
                           details: response_data)
    generate_ticket
  end

  # This method checks to see if any recent BlockedEditAlerts exist.
  def alert_already_exists?
    BlockedEditsAlert.exists?(['created_at >= ?', 8.hours.ago])
  end

  private

  def technical_help_staff
    SpecialUsers.technical_help_staff
  end

  def generate_ticket
    TicketDispenser::Dispenser.call(
      content: @alert.ticket_body,
      details: {
        subject: 'Blocked Edit Alert'
      },
      owner_id: nil,
      project_id: @alert.course_id
    )
  end
end
