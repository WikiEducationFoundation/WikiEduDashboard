# frozen_string_literal: true

# Entry point for LTI 1.3 launches from an LMS, mediated by LTIAAS.
#
# Flow:
#   1. /lti?ltik=... — primary launch endpoint, runs inside the LMS iframe.
#   2. If no current_user, render `sign_in_to_continue` — a tiny iframe view
#      with a `target=_top` link to /lti/escape?ltik=... (browsers refuse
#      to frame Wikipedia OAuth, so we have to break out of the iframe).
#   3. /lti/escape runs at top-level. Without a current_user, it renders
#      an auto-submitting POST form to Devise's omniauth-mediawiki, with
#      the ltik tucked into omniauth.params. After OAuth, the callback
#      resumes the launch by redirecting to /lti?ltik=... at top level.
#   4. With a current_user, build an LtiSession, look up or create the
#      LtiCourseBinding, and link the user via LtiContext. Then:
#      - Instructor + bound course => redirect to course slug
#      - Instructor + unbound      => render the setup view
#      - Student + bound course    => enroll (if needed) and redirect
#      - Student + unbound         => "instructor isn't done yet" view
class LtiLaunchController < ApplicationController
  before_action :require_canvas_integration_enabled
  after_action :allow_iframe, only: %i[launch]

  def launch
    return redirect_to errors_login_error_path if params[:ltik].blank?

    unless current_user
      @ltik = params[:ltik]
      return render 'lti_launch/sign_in_to_continue'
    end

    @lti_session = build_lti_session(params[:ltik])
    @binding = @lti_session.find_or_create_binding!
    @lti_session.link_lti_user(current_user, binding: @binding)

    @lti_session.instructor? ? handle_instructor_launch : handle_student_launch
  end

  def escape_iframe
    return redirect_to errors_login_error_path if params[:ltik].blank?

    unless current_user
      @ltik = params[:ltik]
      return render 'lti_launch/oauth_redirect'
    end

    launch
  end

  def complete_setup
    @binding = LtiCourseBinding.find(params[:binding_id])
    return head :forbidden unless instructor_on_course?(course_from_params)

    @binding.update!(
      course: course_from_params,
      gradebook_granularity: params[:gradebook_granularity]
    )
    LtiRosterSyncWorker.perform_async(@binding.id)
    LtiLineItemSyncWorker.perform_async(@binding.id)
    redirect_to "/courses/#{course_from_params.slug}"
  end

  private

  def build_lti_session(ltik)
    LtiSession.new(ENV['LTIAAS_DOMAIN'], ENV['LTIAAS_API_KEY'], ltik)
  end

  def handle_instructor_launch
    LtiRosterSyncWorker.perform_async(@binding.id) if @binding.course
    return redirect_to "/courses/#{@binding.course.slug}" if @binding.course

    render 'lti_launch/setup'
  end

  def handle_student_launch
    return render 'lti_launch/setup_pending' if @binding.course.nil?
    return redirect_to "/courses/#{@binding.course.slug}" if enrolled?

    JoinCourse.new(course: @binding.course, user: current_user,
                   role: CoursesUsers::Roles::STUDENT_ROLE,
                   real_name: current_user.real_name)
    redirect_to "/courses/#{@binding.course.slug}"
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

    raise ActionController::RoutingError, 'Canvas integration is disabled'
  end
end
