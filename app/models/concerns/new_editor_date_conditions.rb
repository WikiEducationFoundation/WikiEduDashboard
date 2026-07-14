# frozen_string_literal: true

# Shared SQL WHERE conditions for identifying "new editors" —
# students whose Wikipedia account was created during (or shortly before)
# the program they're enrolled in.
#
# Used by SystemStatUpdateWorker and FacilitatorStatUpdateWorker to keep
# the date-window logic in one place and reduce drift risk.
module NewEditorDateConditions
  # Pre-registration window in days (WMF definition).
  PREREGISTRATION_DAYS = 60

  # Registered during the program (start to end).
  DURING_PROGRAM = 'users.registered_at BETWEEN courses.start AND courses.end'

  # Registered up to PREREGISTRATION_DAYS before program start.
  WITH_PREREGISTRATION =
    "users.registered_at BETWEEN DATE_SUB(courses.start, INTERVAL #{PREREGISTRATION_DAYS} DAY) " \
    'AND courses.end'
end
