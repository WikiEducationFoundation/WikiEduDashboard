# frozen_string_literal: true

# Establishing (and refusing) the LTI session behind a launch, mixed into
# LtiLaunchController: build the LtiSession from the ltik, gate on the platform,
# link the launching Dashboard user to the LMS identity, and render the refusals
# for the three ways that can legitimately not work — an unsupported platform, a
# role the integration doesn't serve, and an identity conflict.
#
# Lives in a concern so the launch dispatch in LtiLaunchController stays readable
# and within its length budget, alongside the other launch concerns.
module LtiLaunchSession
  extend ActiveSupport::Concern

  included do
    # Raised from build_lti_session, so it can come from any launch entry point.
    # Handled centrally rather than at each one: nothing downstream of a
    # non-Canvas launch is safe to run, and a rejected platform doesn't need the
    # response to render prettily inside its iframe (this path skips the
    # allow_iframe after_action, so X-Frame-Options stays put — deliberately).
    rescue_from LtiSession::UnsupportedLmsError, with: :render_unsupported_lms
  end

  private

  # Every launch-flow entry point — nav launch, anonymous launch, deep-link
  # picker, grade-sync trigger — builds its session here, so this is the one
  # place the platform gate has to hold.
  def build_lti_session(ltik)
    session = LtiSession.new(ENV['LTIAAS_DOMAIN'], ENV['LTIAAS_API_KEY'], ltik)
    return session if session.supported_lms?

    raise LtiSession::UnsupportedLmsError,
          "launch from unsupported LMS family #{session.lms_family.inspect}"
  end

  # False means the launch authenticated fine but its LMS identity can't be
  # linked to this Dashboard user without changing an existing link — either
  # direction of the 1:1 map is already taken. See
  # LtiSession#reject_conflicting_link!.
  def start_lti_session
    @lti_session = build_lti_session(params[:ltik])
    @binding = @lti_session.find_or_create_binding!
    context = @lti_session.link_lti_user(current_user, binding: @binding)
    schedule_first_link_grade_push(context)
    true
  rescue LtiSession::ConflictingLinkError => e
    Sentry.capture_exception(e, extra: { binding_id: @binding&.id,
                                         user_id: current_user&.id })
    false
  end

  # The "Wikipedia account" column should flip to ✓ the moment a student
  # connects their account, not at the next half-hourly cron — that launch
  # is exactly when they go looking for confirmation. Fires only when this
  # launch newly linked the context (user_id just changed), so routine
  # relaunches don't enqueue redundant syncs.
  def schedule_first_link_grade_push(context)
    return unless @binding.course && context.previous_changes.key?('user_id')

    LtiGradeSyncWorker.perform_async(@binding.id)
  end

  # Reuses the "couldn't enroll you" view: from the student's side a duplicate
  # link and a failed enrollment are the same dead end with the same remedy —
  # contact the instructor — and the view already offers a re-launch retry.
  def render_enrollment_error
    render 'lti_launch/enrollment_error', status: :conflict
  end

  # A Canvas observer or designer, an unrecognized role, or a launch with no
  # roles claim. Same view for the same reason: they can't be enrolled and the
  # remedy is to talk to the instructor. Logged rather than reported to Sentry —
  # it's a legitimate launch by someone the integration doesn't serve, not a
  # fault.
  def render_unsupported_role
    Rails.logger.info(
      "[LTI] unsupported role on launch: binding=#{@binding&.id} " \
      "roles=#{@lti_session.user_roles.inspect}"
    )
    render 'lti_launch/enrollment_error', status: :forbidden
  end

  # The tool is registered per-platform, so this should only ever fire if a
  # non-Canvas platform was registered against the LTIAAS tenant — worth
  # reporting rather than silently refusing.
  def render_unsupported_lms(error)
    Sentry.capture_exception(error)
    head :forbidden
  end

  # Diagnostic, off unless LTI_LAUNCH_DEBUG is set. Logs the launch idtoken's
  # top-level keys, the full `custom` object (Canvas ids + our resource
  # marker — not PII), and the AGS service keys + lineItemId value (never the
  # serviceKey value). Confirms what a deep-link-created resource link's
  # launch actually carries on staging.
  def log_launch_claims
    idt = @lti_session.idtoken
    ags = idt.dig('services', 'assignmentAndGrades') || {}
    Rails.logger.warn("[LTI launch] top=#{idt.keys.inspect} custom=#{idt['custom'].inspect} " \
                      "ags_keys=#{ags.keys.inspect} lineItemId=#{ags['lineItemId'].inspect}")
  end
end
