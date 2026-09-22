# frozen_string_literal: true

class BlockedEditsReporter
  def self.create_alerts_for_blocked_edits(user, response_data, wiki = nil)
    new.create_alert(user, response_data, wiki)
  end

  def create_alert(user, response_data, wiki = nil)
    return if alert_already_exists?
    details = wiki ? response_data.merge('wiki_domain' => wiki.domain) : response_data
    @alert = Alert.create!(type: 'BlockedEditsAlert',
                           user_id: user.id,
                           target_user_id: technical_help_staff&.id,
                           details:)
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
