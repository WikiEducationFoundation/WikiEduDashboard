# frozen_string_literal: true

# View helpers for the in-Canvas LTI launch views.
module LtiLaunchHelper
  # Maps a three-state progress value (:complete / :partial / :none) to the
  # status-pill CSS class, so a not-started or partially-done row is
  # visually distinct from a complete one.
  PROGRESS_PILL_CLASSES = {
    complete: 'lti-status--done',
    partial: 'lti-status--partial',
    none: 'lti-status--pending'
  }.freeze

  def lti_progress_pill_class(state)
    PROGRESS_PILL_CLASSES.fetch(state, 'lti-status--pending')
  end

  # Status-label i18n key for a three-state progress value, so the exercise
  # roster and student panel share one complete/in-progress/not-started label.
  PROGRESS_STATUS_KEYS = {
    complete: 'completed',
    partial: 'in_progress',
    none: 'not_started'
  }.freeze

  def lti_progress_status_label(state)
    t("lti.assignment_view.status.#{PROGRESS_STATUS_KEYS.fetch(state, 'not_started')}")
  end

  # "%{time} ago" for a sync timestamp, or the "not yet synced" copy when nil.
  # Shared by the roster row and the grade-sync partial so the two read the same.
  def lti_last_synced(time)
    return t('lms_integration.never_synced') if time.nil?

    t('lms_integration.time_ago', time_ago: time_ago_in_words(time))
  end
end
