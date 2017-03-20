# frozen_string_literal: true
module AlertsHelper
  def alert_display
    if alert.resolvable? == true && alert.resolved == true then
      '✓'
    elsif alert.resolvable? == true && alert.resolved == false then
      button_to('Resolve', resolve_alert_path(alert.id), method: :put,
      class: 'button small danger dark')
    end
  end
end
