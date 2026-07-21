# frozen_string_literal: true

# Launch handling when there is no Rails session — the NORMAL state inside
# the Canvas iframe, where cookies are partitioned away from the top-level
# dashboard session. The ltik still authenticates the launch (LTIAAS
# validates it and serves the idtoken), so read-only views keyed off the
# LTI identity render right in the iframe: assignment drill-downs and the
# bound-course status view. The deep-link picker already works exactly this
# way. Only flows that need the Dashboard account itself (Wikipedia OAuth
# linking, student enrollment, the setup form) still bounce through the
# new-tab landing.
module LtiAnonymousLaunch
  extend ActiveSupport::Concern

  private

  def handle_anonymous_launch
    @ltik = params[:ltik]
    @lti_session = anonymous_lti_session
    @binding = @lti_session&.bound_binding
    return render_anonymous_assignment_view if @binding && assignment_launch?
    return render_instructor_status if @binding && @lti_session.instructor?
    # A linked student who's already enrolled needs nothing from the new-tab
    # flow — confirm and link out. (Enrolling itself still needs a session.)
    return render 'lti_launch/student_status' if @binding && enrolled?(launch_viewer)

    @show_not_linked_notice = @lti_session.present? && @binding.nil? &&
                              @lti_session.instructor?
    render 'lti_launch/sign_in_to_continue', layout: 'lti_iframe'
  end

  # nil on any failure (expired ltik, LTIAAS hiccup): the landing must keep
  # rendering, just without launch-specific state.
  def anonymous_lti_session
    build_lti_session(params[:ltik])
  rescue StandardError
    nil
  end

  # Instructors see the roster views with no Dashboard account at all; a
  # student needs a linked Wikipedia account before there is a panel to
  # show, so unlinked students get the landing — whose new-tab flow is
  # exactly what links them.
  def render_anonymous_assignment_view
    return render_assignment_view if @lti_session.instructor? || launch_viewer

    render 'lti_launch/sign_in_to_continue', layout: 'lti_iframe'
  end
end
