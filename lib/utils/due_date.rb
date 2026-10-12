# frozen_string_literal: true

#= Whether a timeline due date has passed. Due dates are plain dates with no
# time zone, so a date only counts as passed once it has ended everywhere on
# Earth (UTC−12). Comparing against the server's UTC date instead flagged work
# as overdue from late afternoon on the due date in the Americas.
class DueDate
  ANYWHERE_ON_EARTH = ActiveSupport::TimeZone['International Date Line West'] # UTC−12

  def self.passed?(date)
    date.present? && Time.current.in_time_zone(ANYWHERE_ON_EARTH).to_date > date
  end
end
