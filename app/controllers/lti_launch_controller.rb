# frozen_string_literal: true

# Entry point for LTI 1.3 launches from an LMS, mediated by LTIAAS.
#
# Flow:
#   1. /lti?ltik=... — primary launch endpoint, runs inside the LMS iframe.
#   2. If no current_user (the normal state in the iframe — cookies there
#      are partitioned away from the top-level dashboard session), the ltik
#      still authenticates the launch, so read-only views render in place:
#      assignment drill-downs and the bound-course status view (see
#      LtiAnonymousLaunch). Everything else gets `sign_in_to_continue` — a
#      minimal iframe view with a `target=_blank` link to
#      /lti/connect_course?ltik=... (browsers refuse to frame Wikipedia
#      OAuth, so account flows happen outside the iframe). Opens in a new
#      tab so the Canvas page stays put.
#   3. /lti/connect_course runs at top-level in the new tab. Without a
#      current_user, it stashes the ltik in session and renders an
#      auto-submitting POST form to Devise's omniauth-mediawiki. After
#      OAuth, the callback reads the ltik back from session and redirects
#      to /lti?ltik=... at top level — so the user lands on a clean URL,
#      not on /lti/connect_course. With a current_user, connect_course
#      falls through to the launch flow directly (no OAuth bounce).
#   4. With a current_user, build an LtiSession, look up or create the
#      LtiCourseBinding, and link the user via LtiContext. Then:
#      - Assignment launch         => the drill-down (enrolling a student
#                                     first, since that may be the only
#                                     launch they ever make)
#      - Instructor + bound course => the in-iframe status view
#      - Instructor + unbound      => render the setup view
#      - Student + bound course    => enroll (if needed) and redirect
#      - Student + unbound         => "instructor isn't done yet" view
#
# Nothing in that dispatch is specific to the course-navigation placement:
# an institution can leave the nav tab off and drive the whole integration
# from the deep-link / assignment launches instead.
class LtiLaunchController < ApplicationController
  include LtiDeepLinking
  include LtiAssignmentViews
  include LtiStudentEnrollment
  include LtiAnonymousLaunch
  include LtiGradeSyncTrigger
  include LtiLaunchSession

  # Every launch-flow view is a minimal, chrome-less page rather than the full
  # dashboard React shell. The setup / setup_pending / enrollment_* views were
  # relying on the default `application` layout, whose client JS swallowed the
  # plain setup form's submit (the bind POST never reached the server); the
  # navbar also reads a misleading logged-out state inside the Canvas iframe.
  # Individual renders may still override this default.
  layout 'lti_iframe'

  before_action :require_canvas_integration_enabled
  # THE one registration of allow_iframe for this controller, listing every
  # action whose response renders inside a Canvas iframe: the launch views, the
  # setup POST, the deep-linking picker and its form (Canvas's "Find" dialog),
  # and the in-frame grade-sync POST.
  #
  # It has to be one registration. ActiveSupport's callback chain treats two
  # `after_action :allow_iframe` declarations as duplicates of the same filter
  # and keeps only the last one, so a concern that registered its own action
  # here — as LtiGradeSyncTrigger did for sync_grades — had its registration
  # silently deleted by this line, which is evaluated after the includes above.
  # The action still rendered 200, and the browser refused the frame: the
  # instructor's grade-sync button produced "refused to connect" with no
  # in-frame anything. Add actions to this list; never re-register the filter.
  after_action :allow_iframe,
               only: %i[launch assignment_view complete_setup connect_identity
                        deep_link deep_link_select sync_grades]

  def launch
    return render_launch_error_or_redirect if params[:ltik].blank?
    return handle_anonymous_launch unless current_user

    return render_enrollment_error unless start_lti_session
    # Nothing links until the user says so — see #connect_identity.
    return render_connect_identity if @lti_context.nil?

    log_launch_claims if ENV['LTI_LAUNCH_DEBUG']
    return assignment_launch_response if assignment_launch?
    # An assignment launch above still renders (read-only, no enrollment — see
    # LtiStudentEnrollment#enrollable_student?), but there is no course-nav view
    # for someone who is neither staff nor learner.
    return render_unsupported_role if @lti_session.unsupported_role?

    @lti_session.instructor? ? handle_instructor_launch : handle_student_launch
  end

  def connect_course
    return redirect_to errors_login_error_path if params[:ltik].blank?

    unless current_user
      session['ltik'] = params[:ltik]
      return render 'lti_launch/oauth_redirect', layout: 'lti_iframe'
    end

    launch
  end

  # Standalone entry for the `assignment_view` placement. LTIAAS forwards
  # every core launch to a single Launch URL (/lti), so in the current
  # setup assignment-context launches arrive at #launch and are dispatched
  # there by `assignment_launch?`. This route is kept as a harmless
  # fallback in case a launch is ever routed straight here (e.g. an LMS or
  # config that honors the per-placement target_link_uri); it shares all of
  # #launch's logic, including the same iframe break-out + OAuth flow.
  def assignment_view
    launch
  end

  # Connects the signed-in Dashboard account to this launch's LMS identity —
  # the only path that creates a link, and only ever from the user's own click on
  # the approval view. A launch used to do this silently, which connected
  # whichever account the browser was signed into and, because the link is
  # write-once, could not be corrected without staff clearing the row.
  #
  # CSRF protection is deliberately NOT skipped here, unlike the in-frame picker
  # POST: this action requires `current_user`, so a Rails session always exists
  # and the token both applies and works. The identity itself comes from the
  # re-verified ltik, never from submitted params.
  def connect_identity
    return render_launch_error_or_redirect if params[:ltik].blank?
    return head :forbidden unless current_user

    return render_enrollment_error unless start_lti_session
    return launch if @lti_context # already linked; nothing to approve

    @lti_context = @lti_session.link_lti_user(current_user, binding: @binding)
    schedule_first_link_grade_push(@lti_context)
    launch
  rescue LtiSession::ConflictingLinkError
    # Lost a race between the approval view's check and this write.
    @link_conflict = :identity_taken
    render_enrollment_error
  end

  # The binding being linked is derived from a freshly verified ltik, never
  # from a submitted id. Trusting `params[:binding_id]` let any signed-in
  # instructor bind an arbitrary unbound binding — some other institution's
  # Canvas course, found by guessing a small integer — to a Dashboard course
  # they teach, which would then pull that Canvas roster in and push grades
  # back to it. The ltik is what proves this POST belongs to a real launch
  # from the Canvas course being linked, and the launch's own roles have to
  # say instructor. The target course is restricted to the same server-derived
  # `linkable_courses` list the picker was built from.
  def complete_setup
    return render_launch_error_or_redirect if params[:ltik].blank?
    return head :forbidden unless current_user

    return render_setup_link_error unless start_lti_session
    return head :forbidden unless @lti_session.instructor? && binding_unclaimed?
    return render_already_linked if course_bound_elsewhere?
    return head :forbidden unless linkable_courses.include?(course_from_params)
    return render_already_linked unless bind_course_and_sync

    confirm_setup
  end

  private

  # An assignment-context launch is identifiable three ways: the deep-link
  # `resource` marker we stamp on every deep-link-created assignment (echoed back
  # under the `custom` claim), the singular AGS line-item URL, and/or the
  # `canvas_assignment_id` custom field. A deep-link-created assignment reliably
  # carries only the resource marker — Canvas doesn't always deliver a scoped
  # lineItemId on the launch, and we don't set canvas_assignment_id on the content
  # item — so without the marker those launches fall through to the course page
  # instead of the roster. The course-navigation launch carries none of the three.
  def assignment_launch?
    @lti_session.deep_link_resource.present? ||
      @lti_session.canvas_assignment_id.present? ||
      @lti_session.ags_lineitem_url.present?
  end

  # An assignment launch renders the drill-down, but for a student it also
  # has to do the enrolling the course-navigation launch would have done —
  # see LtiStudentEnrollment#ensure_launch_enrollment.
  def assignment_launch_response
    return render 'lti_launch/enrollment_pending_approval' unless ensure_launch_enrollment

    render_assignment_view
  end

  def handle_instructor_launch
    return render_instructor_status if @binding.course

    prepare_setup_view
    render 'lti_launch/setup'
  end

  # The course-navigation launch for an already-linked course. Confirm the
  # link and show sync status in the iframe rather than redirecting into the
  # full dashboard: the React shell reads a logged-out session inside the
  # Canvas iframe (cookies are partitioned), and instructors re-open this
  # nav item mainly to check that roster/grade sync is working. Each launch
  # also kicks off a fresh roster sync, so the numbers shown may lag it by
  # a few moments.
  def render_instructor_status(sync_roster: true)
    LtiRosterSyncWorker.perform_async(@binding.id) if sync_roster
    @sync_status = LtiSyncStatus.new(@binding)
    render 'lti_launch/instructor_status'
  end

  # Assigns for the setup view. An instructor with no Dashboard courses at
  # all is a different case from one whose courses just aren't linkable
  # (unapproved, ended, withdrawn, or already linked): the first needs the
  # create-a-course path, not an approval message about courses that don't
  # exist.
  def prepare_setup_view
    @user_courses = linkable_courses
    @no_courses_yet = @user_courses.empty? && current_user.instructed_courses.none?
  end

  # Approved, not-yet-ended courses the instructor teaches, minus any already
  # bound to another LMS course — a Dashboard course backs only one LMS course
  # (unique index on course_id), so listing a linked one would dead-end the
  # setup POST. complete_setup guards the same case server-side.
  def linkable_courses
    # The course_id filter is load-bearing: `NOT IN (subquery)` would exclude
    # every course if the subquery yielded a NULL.
    bound = LtiCourseBinding.where.not(id: @binding&.id)
                            .where.not(course_id: nil).select(:course_id)
    current_user.instructed_courses
                .joins(:campaigns_courses)
                .where(withdrawn: false)
                .where('courses.end > ?', Time.zone.now)
                .where.not(id: bound)
                .distinct.order(start: :desc).to_a
  end

  # In-iframe setup (Firefox lets the iframe keep the session) can't redirect
  # to the course page — its X-Frame-Options blocks framing — so the status
  # view IS the confirmation there. Top level, the course page's flash banner
  # (shared/_flash) confirms the link instead.
  def confirm_setup
    return render_instructor_status if framed_request?

    redirect_to "/courses/#{course_from_params.slug}",
                notice: t('lti.setup.linked_notice',
                          lms_course: @binding.lms_context_title || @binding.lms_display_name)
  end

  def course_from_params
    @course_from_params ||= Course.find_by(slug: params[:course_slug])
  end

  # Rebinding an already-linked Canvas course isn't part of any flow: an
  # instructor launch for a bound binding renders the status view, never the
  # setup form. So a POST that would move a claimed binding is a replayed form
  # or tampering; reassignment needs its own authorized flow. Re-submitting the
  # same pairing stays idempotent.
  def binding_unclaimed?
    @binding.course_id.nil? || @binding.course_id == course_from_params&.id
  end

  # A Dashboard course can back only one LMS course. If the chosen one is already
  # bound to a different binding, re-render setup (the picker already omits it)
  # rather than letting the unique index raise a 500 from update!.
  def course_bound_elsewhere?
    course_from_params &&
      LtiCourseBinding.where.not(id: @binding.id)
                      .exists?(course_id: course_from_params.id)
  end

  def render_already_linked
    prepare_setup_view
    @setup_error = t('lti.setup.already_linked')
    render 'lti_launch/setup', status: :unprocessable_entity
  end

  # Deep-link-first: no gradebook-layout choice — the binding keeps its default
  # (lumped), nothing is auto-created, and the instructor imports columns via
  # the Canvas Modules "Import Wikipedia assignments" flow. The course's
  # `canvas_integration` flag follows from the binding (LtiCourseBinding keeps
  # the two in step), so it isn't set here.
  #
  # Returning false means a concurrent bind of the same Dashboard course won the
  # race — the unique index on course_id is the authority — which the caller
  # reports the same way as the pre-checked case.
  def bind_course_and_sync
    @binding.update!(course: course_from_params)
    LtiRosterSyncWorker.perform_async(@binding.id)
    LtiLineItemSyncWorker.perform_async(@binding.id)
    true
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
    false
  end

  def allow_iframe
    response.headers.except! 'X-Frame-Options'
  end

  # Whether this request is being rendered inside a frame (the Canvas
  # iframe) rather than a top-level tab. All current browsers send
  # Sec-Fetch-Dest; a missing header (very old browser) reads as top-level,
  # which degrades to the old redirect behavior.
  def framed_request?
    request.headers['Sec-Fetch-Dest'] == 'iframe'
  end

  def require_canvas_integration_enabled
    return if Features.canvas_integration?

    # Render 404 directly rather than `raise ActionController::RoutingError`:
    # in production envs the routing-error middleware only catches errors
    # raised by the routing layer itself, not from a before_action callback,
    # so the raise would surface as a 500 to the LMS. The test env handles
    # this differently which is why the 404 spec passed under either form.
    head :not_found
  end
end
