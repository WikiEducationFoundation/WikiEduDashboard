# frozen_string_literal: true

# View helpers for the in-Canvas LTI launch views.
module LtiLaunchHelper
  # The Dashboard account a page is acting as, for the identity line the
  # lti_iframe layout renders on every page.
  #
  # NOT simply `current_user`. Inside the Canvas iframe the session cookie is
  # partitioned away, so `current_user` is nil there — while the views are
  # perfectly happy showing that person's roster, progress and sandboxes, having
  # resolved them from the launch's LMS identity instead
  # (LtiAssignmentViews#launch_viewer, LtiAnonymousLaunch). Reading `current_user`
  # alone therefore made every framed page claim nobody was signed in while
  # displaying the signed-in user's own data — the contradiction this line exists
  # to prevent.
  #
  # Order: the session when there is one (a top-level tab), then whatever the
  # launch already resolved, then the account connected to this launch's identity.
  # nil only when no account is known at all, which is the state the anonymous
  # landing is asking the user to fix.
  def lti_page_account
    return current_user if current_user
    return @launch_viewer if @launch_viewer
    return if @lti_session.nil? || @binding.nil?

    LtiContext.connected_user(binding_id: @binding.id,
                              user_lti_id: @lti_session.user_lti_id)
  end
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

  # Timeline block content rendered inside the Canvas iframe: sanitized
  # first, then links are rewritten to open outside the iframe (the
  # sanitizer strips `target`, and Dashboard-relative links would otherwise
  # blank the frame via X-Frame-Options). html_safe rests solely on that
  # sanitize + post-process pipeline.
  def lti_iframe_content(content)
    RewriteLtiContentLinks.new(sanitize(content)).html.html_safe # rubocop:disable Rails/OutputSafety
  end

  # "%{time} ago" for a sync timestamp, or the "not yet synced" copy when nil.
  # Shared by the roster row and the grade-sync partial so the two read the same.
  def lti_last_synced(time)
    return t('lms_integration.never_synced') if time.nil?

    t('lms_integration.time_ago', time_ago: time_ago_in_words(time))
  end
end
