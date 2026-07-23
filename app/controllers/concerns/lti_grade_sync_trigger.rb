# frozen_string_literal: true

# Instructor-initiated grade sync from inside the Canvas iframe.
#
# The status and assignment drill-down views only ever kicked off a *roster*
# sync on launch; grade sync otherwise waited for the ~30-minute cron
# (LtiPeriodicGradeSyncWorker) or a student's first account link. So after a
# student finished a training or connected their account, an instructor had no
# way to push fresh grades — the column just read "no grade" until the cron ran.
#
# This adds a POST that enqueues LtiGradeSyncWorker for the launch's bound
# binding and re-renders the same view (status or assignment drill-down),
# flagging @grade_sync_started so the view can confirm it. Async by design:
# a grade sync makes one LTIAAS AGS POST per student x column, too much to run
# inline in an iframe request. Authenticated by the ltik like every other
# in-iframe action; CSRF is skipped because the partitioned iframe has no Rails
# session (same as the deep-link picker POST).
module LtiGradeSyncTrigger
  extend ActiveSupport::Concern

  included do
    skip_before_action :verify_authenticity_token, only: :sync_grades
    after_action :allow_iframe, only: :sync_grades
  end

  def sync_grades
    return redirect_to errors_login_error_path if params[:ltik].blank?

    @ltik = params[:ltik]
    @lti_session = anonymous_lti_session
    @binding = @lti_session&.bound_binding
    return redirect_to errors_login_error_path unless @binding && @lti_session.instructor?

    LtiGradeSyncWorker.perform_async(@binding.id) if @binding.course
    @grade_sync_started = true
    return render_assignment_view if assignment_launch?

    render_instructor_status(sync_roster: false)
  end
end
