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

  # "%{time} ago" for a sync timestamp, or the "not yet synced" copy when nil.
  # Shared by the roster row and the grade-sync partial so the two read the same.
  def lti_last_synced(time)
    return t('lms_integration.never_synced') if time.nil?

    t('lms_integration.time_ago', time_ago: time_ago_in_words(time))
  end
end
