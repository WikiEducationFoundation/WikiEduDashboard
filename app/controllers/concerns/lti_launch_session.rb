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
    # Any LTIAAS refusal or outage mid-launch — most commonly an expired ltik
    # on a stale Canvas tab. Unrescued, these 500 with the default
    # X-Frame-Options, which the Canvas iframe shows as a blank "refused to
    # connect"; render a friendly in-frame page instead. (The anonymous
    # launch's landing already degrades on these — see anonymous_lti_session —
    # so this covers the signed-in and picker paths.)
    rescue_from LtiaasClient::LtiaasClientError, LtiaasClient::LtiaasTransientError,
                with: :render_ltiaas_error
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
  # direction of the 1:1 map is already taken. `@link_conflict` says which,
  # because the identity-taken case has a self-service remedy and the other
  # doesn't.
  #
  # This no longer creates a link. It refreshes one that exists (LMS role
  # changes have to keep propagating) and leaves `@lti_context` nil otherwise,
  # which is the caller's signal to ask the user first — see
  # LtiLaunchController#connect_identity. Linking as a side effect of arriving
  # with a session is how an instructor's Canvas identity got silently connected
  # to whichever Dashboard account their browser was signed into.
  def start_lti_session
    @lti_session = build_lti_session(params[:ltik])
    @binding = @lti_session.find_or_create_binding!
    @link_conflict = @lti_session.link_conflict(current_user, binding: @binding)
    return report_link_conflict if @link_conflict

    @lti_context = @lti_session.refresh_existing_link(current_user, binding: @binding)
    true
  end

  def report_link_conflict
    Sentry.capture_exception(
      LtiSession::ConflictingLinkError.new("#{@link_conflict} on launch"),
      extra: { binding_id: @binding&.id, user_id: current_user&.id }
    )
    false
  end

  # Nothing is linked yet, so ask before writing: the approval view names the
  # Canvas course and the Dashboard account, and its POST is the only path that
  # creates a link.
  def render_connect_identity
    render 'lti_launch/connect_identity', layout: 'lti_iframe'
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

  # Reuses the "couldn't enroll you" view: from the student's side a failed
  # enrollment and a link this launch may not move are the same dead end with the
  # same remedy — contact the instructor — and the view already offers a
  # re-launch retry.
  #
  # Except for the one conflict that has a self-service remedy. When this Canvas
  # identity is already connected to a different Dashboard account, the fix is to
  # sign back in as that account, and the setup flow has said so all along
  # (`lti.setup.duplicate_link_error`) while the launch path sent instructors and
  # students alike to "contact your instructor". Deliberately does NOT name the
  # account that holds the link: it would identify the remedy precisely, but a
  # Wikipedia username would then be disclosed to whoever holds the launch URL.
  def render_enrollment_error
    return render_duplicate_link_error if @link_conflict == :identity_taken

    render 'lti_launch/enrollment_error', status: :conflict
  end

  def render_duplicate_link_error
    @setup_error = t('lti.setup.duplicate_link_error')
    render 'lti_launch/enrollment_error', status: :conflict
  end

  # complete_setup's audience is the instructor running setup, so its link
  # refusal must not reuse the student-facing "contact your instructor"
  # enrollment error. Re-render setup with an error banner instead, naming
  # the self-service remedy for the one conflict that has one: a duplicate
  # link (this Canvas user already linked a different Dashboard account —
  # signing back in with that account fixes it without staff).
  def render_setup_link_error
    prepare_setup_view
    @setup_error = t(setup_link_error_key)
    render 'lti_launch/setup', status: :conflict
  end

  def setup_link_error_key
    if @link_conflict == :identity_taken
      'lti.setup.duplicate_link_error'
    else
      'lti.setup.link_conflict_error'
    end
  end

  # An expired ltik (LTIAAS 401) is routine, so it's logged rather than
  # reported; anything else — rate limits, outages, unexpected 4xx — goes to
  # Sentry. Framing is re-allowed explicitly because rescue_from skips the
  # allow_iframe after_action that would normally clear X-Frame-Options.
  def render_ltiaas_error(error)
    if error.is_a?(LtiaasClient::LtiaasAuthError)
      Rails.logger.info("[LTI] LTIAAS auth failure on #{action_name}: #{error.message}")
    else
      Sentry.capture_exception(error)
    end
    allow_iframe
    render 'lti_launch/launch_error', layout: 'lti_iframe', status: :bad_gateway
  end

  # Refusals on the framed entry points can't redirect to the login-error
  # page: its X-Frame-Options blocks the Canvas iframe, so the redirect shows
  # up as a blank "refused to connect". Render the friendly in-frame error
  # instead; a top-level request keeps the old redirect.
  def render_launch_error_or_redirect
    return redirect_to errors_login_error_path unless framed_request?

    allow_iframe
    render 'lti_launch/launch_error', layout: 'lti_iframe', status: :unprocessable_entity
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
