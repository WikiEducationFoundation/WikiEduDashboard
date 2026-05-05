# frozen_string_literal: true

# Entry point for LTI 1.3 launches from an LMS, mediated by LTIAAS.
#
# Flow:
#   1. /lti?ltik=... — primary launch endpoint
#   2. If no current_user, stash the ltik in session and bounce to
#      Wikipedia OAuth; on return the OmniauthCallbacksController
#      restores the ltik and redirects back here.
#   3. With a current_user, build an LtiSession, look up or create the
#      LtiCourseBinding, and link the user via LtiContext.
#   4. Branch on instructor vs. student:
#      - Instructor + bound course => redirect to course slug
#      - Instructor + unbound      => render the setup view
#      - Student + bound course    => enroll (if needed) and redirect
#      - Student + unbound         => "instructor isn't done yet" view
#
# /lti/escape provides a top-level (non-iframe) version for the
# Safari/Chrome 3PC fallback.
class LtiLaunchController < ApplicationController
  after_action :allow_iframe, only: %i[launch]

  def launch
    return redirect_to errors_login_error_path if params[:ltik].blank?

    unless current_user
      session['ltik'] = params[:ltik]
      return redirect_to user_mediawiki_omniauth_authorize_path
    end

    @lti_session = build_lti_session(params[:ltik])
    @binding = @lti_session.find_or_create_binding!
    @lti_session.link_lti_user(current_user, binding: @binding)

    @lti_session.instructor? ? handle_instructor_launch : handle_student_launch
  end

  def escape_iframe
    return redirect_to errors_login_error_path if params[:ltik].blank?

    unless current_user
      session['ltik'] = params[:ltik]
      return redirect_to user_mediawiki_omniauth_authorize_path
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
    redirect_to "/courses/#{course_from_params.slug}"
  end

  private

  def build_lti_session(ltik)
    LtiSession.new(ENV['LTIAAS_DOMAIN'], ENV['LTIAAS_API_KEY'], ltik)
  end

  def handle_instructor_launch
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
end
