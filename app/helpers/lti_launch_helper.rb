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
end
