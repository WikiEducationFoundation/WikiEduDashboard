# frozen_string_literal: true

module AlertsListHelper
  def alert_display(alert)
    return '✓' if alert.resolved?
    resolve_button(alert) if alert.resolvable? # implicit return
  end

  def resolve_button(alert)
    button_to('Resolve', resolve_alert_path(alert), method: :put, class: 'button small danger dark')
  end
end
