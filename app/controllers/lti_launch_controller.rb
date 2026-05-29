# frozen_string_literal: true

# Entry point for LTI 1.3 launches from an LMS, mediated by LTIAAS.
#
# Flow:
#   1. /lti?ltik=... — primary launch endpoint, runs inside the LMS iframe.
#   2. If no current_user, render `sign_in_to_continue` — a minimal iframe
#      view with a `target=_blank` link to /lti/connect_course?ltik=...
#      (browsers refuse to frame Wikipedia OAuth, and cookies inside the
#      Canvas iframe are partitioned away from the top-level dashboard
#      session, so the rest of the launch has to happen outside the iframe).
#      Opens in a new tab so the Canvas page stays put.
#   3. /lti/connect_course runs at top-level in the new tab. Without a
#      current_user, it stashes the ltik in session and renders an
#      auto-submitting POST form to Devise's omniauth-mediawiki. After
#      OAuth, the callback reads the ltik back from session and redirects
#      to /lti?ltik=... at top level — so the user lands on a clean URL,
#      not on /lti/connect_course. With a current_user, connect_course
#      falls through to the launch flow directly (no OAuth bounce).
#   4. With a current_user, build an LtiSession, look up or create the
#      LtiCourseBinding, and link the user via LtiContext. Then:
#      - Instructor + bound course => redirect to course slug
#      - Instructor + unbound      => render the setup view
#      - Student + bound course    => enroll (if needed) and redirect
#      - Student + unbound         => "instructor isn't done yet" view
class LtiLaunchController < ApplicationController
  before_action :require_canvas_integration_enabled
  after_action :allow_iframe, only: %i[launch assignment_view]

  def launch
    return redirect_to errors_login_error_path if params[:ltik].blank?

    unless current_user
      @ltik = params[:ltik]
      return render 'lti_launch/sign_in_to_continue', layout: 'lti_iframe'
    end

    @lti_session = build_lti_session(params[:ltik])
    @binding = @lti_session.find_or_create_binding!
    @lti_session.link_lti_user(current_user, binding: @binding)

    @lti_session.instructor? ? handle_instructor_launch : handle_student_launch
  end

  def connect_course
    return redirect_to errors_login_error_path if params[:ltik].blank?

    unless current_user
      session['ltik'] = params[:ltik]
      session['lti_return_to'] = 'assignment_view' if assignment_view_return?
      return render 'lti_launch/oauth_redirect', layout: 'lti_iframe'
    end

    assignment_view_return? ? assignment_view : launch
  end

  # The instructor (or student) drill-down rendered when a Wikipedia
  # gradebook column is opened inside Canvas via the `assignment_view`
  # placement. Inside the Canvas iframe cookies are partitioned, so the
  # first hit has no current_user and breaks out to a top-level tab via
  # connect_course (return_to=assignment_view), exactly like the main
  # launch. At top level we resolve which line item was clicked and render
  # the roster (instructor) or the student's own panel.
  def assignment_view
    return redirect_to errors_login_error_path if params[:ltik].blank?

    unless current_user
      @ltik = params[:ltik]
      @connect_return_to = 'assignment_view'
      return render 'lti_launch/sign_in_to_continue', layout: 'lti_iframe'
    end

    @lti_session = build_lti_session(params[:ltik])
    @binding = @lti_session.find_or_create_binding!
    @lti_session.link_lti_user(current_user, binding: @binding)
    render_assignment_view
  end

  def complete_setup
    @binding = LtiCourseBinding.find(params[:binding_id])
    return head :forbidden unless instructor_on_course?(course_from_params)

    @binding.update!(
      course: course_from_params,
      gradebook_granularity: params[:gradebook_granularity]
    )
    course_from_params.flags[:canvas_integration] = true
    course_from_params.save
    LtiRosterSyncWorker.perform_async(@binding.id)
    LtiLineItemSyncWorker.perform_async(@binding.id)
    redirect_to "/courses/#{course_from_params.slug}"
  end

  private

  def build_lti_session(ltik)
    LtiSession.new(ENV['LTIAAS_DOMAIN'], ENV['LTIAAS_API_KEY'], ltik)
  end

  def assignment_view_return?
    params[:return_to] == 'assignment_view'
  end

  def render_assignment_view
    line_item = ResolveAssignmentLineItem.new(binding: @binding,
                                              lti_session: @lti_session).result
    if line_item.nil? || line_item.gradable_type != 'Block'
      return render 'lti_launch/assignment_view_orphan', layout: 'lti_iframe'
    end

    @context = AssignmentViewContext.new(line_item:, user: current_user,
                                         instructor: @lti_session.instructor?)
    render 'lti_launch/assignment_view', layout: 'lti_iframe'
  end

  def handle_instructor_launch
    LtiRosterSyncWorker.perform_async(@binding.id) if @binding.course
    return redirect_to "/courses/#{@binding.course.slug}" if @binding.course

    @user_courses = current_user.instructed_courses
                                .joins(:campaigns_courses)
                                .where(withdrawn: false)
                                .where('courses.end > ?', Time.zone.now)
                                .distinct.order(start: :desc).to_a
    render 'lti_launch/setup'
  end

  def handle_student_launch
    return render 'lti_launch/setup_pending' if @binding.course.nil?
    return redirect_to "/courses/#{@binding.course.slug}" if enrolled?

    result = join_course_for_student
    return redirect_to "/courses/#{@binding.course.slug}" if join_succeeded?(result)
    return render 'lti_launch/enrollment_pending_approval' if pending_approval?(result)

    report_join_failure(result)
    render 'lti_launch/enrollment_error'
  end

  def join_course_for_student
    JoinCourse.new(course: @binding.course, user: current_user,
                   role: CoursesUsers::Roles::STUDENT_ROLE,
                   real_name: current_user.real_name).result
  end

  def join_succeeded?(result)
    result['success'] || result['failure'] == 'cannot_join_twice'
  end

  def pending_approval?(result)
    result['failure'] == 'not_yet_approved'
  end

  def report_join_failure(result)
    Sentry.capture_message(
      'LTI student launch JoinCourse failure',
      extra: { binding_id: @binding.id, user_id: current_user.id,
               failure: result['failure'] }
    )
  end

  def enrolled?
    CoursesUsers.exists?(user_id: current_user.id, course_id: @binding.course_id)
  end

  def course_from_params
    @course_from_params ||= Course.find_by(slug: params[:course_slug])
  end

  def instructor_on_course?(course)
    return false unless course && current_user

    CoursesUsers.exists?(user_id: current_user.id, course_id: course.id,
                         role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
  end

  def allow_iframe
    response.headers.except! 'X-Frame-Options'
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
