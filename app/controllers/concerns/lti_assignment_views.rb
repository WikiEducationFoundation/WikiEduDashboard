# frozen_string_literal: true

# Assignment-context launch rendering for the LTI flow, mixed into
# LtiLaunchController: resolves which gradebook column a launch came from
# and renders its drill-down — the roster/sandbox view for exercise Blocks,
# the account-connection view for the WikipediaSetup column, and the
# progress view for the TrainingProgress roll-up. Anything unresolvable
# falls to the orphan view.
#
# Lives in a concern so the shared launch plumbing (build_lti_session,
# allow_iframe, the canvas-integration flag gate) stays in one place while
# keeping LtiLaunchController within its length budget.
module LtiAssignmentViews
  extend ActiveSupport::Concern

  private

  def render_assignment_view
    # The course + synced line items live on the context's *bound* binding.
    # `find_or_create_binding!` resolves there too once a course is linked,
    # but the anonymous path sets `@binding` straight from the launch, so
    # resolve explicitly and fall back to the launch binding when the context
    # isn't linked to a Dashboard course yet.
    binding = @lti_session.bound_binding || @binding
    return render_submission_placeholder(binding) if params[:submission].present?
    line_item = ResolveAssignmentLineItem.new(binding:, lti_session: @lti_session).result
    template, @context = assignment_view_for(line_item)
    return render 'lti_launch/assignment_view_orphan', layout: 'lti_iframe' if template.nil?

    render "lti_launch/#{template}", layout: 'lti_iframe'
  end

  # A launch from a student's submission in Canvas — SpeedGrader or the submission
  # page — rather than from the assignment itself. Marked by `submission` on the
  # URL we hand Canvas as the submission's own (SyncLtiGrades#submission_launch_url),
  # so it can't be confused with an ordinary assignment launch.
  #
  # There is no per-student submission view yet, and Canvas's fallback for an
  # assignment whose grade arrived by AGS is a bare "No Preview Available". Say what
  # is actually going on and point at the Dashboard instead.
  def render_submission_placeholder(binding)
    @submission_course = binding&.course
    render 'lti_launch/assignment_view_submission', layout: 'lti_iframe'
  end

  # Template + view context for the resolved line item's gradable type.
  def assignment_view_for(line_item)
    instructor = @lti_session.instructor?
    user = launch_viewer
    case line_item&.gradable_type
    when 'Block'
      ['assignment_view', AssignmentViewContext.new(line_item:, user:, instructor:)]
    when LtiLineItem::SETUP_TYPE
      ['assignment_view_setup', SetupAssignmentViewContext.new(line_item:, instructor:, user:)]
    when LtiLineItem::TRAINING_PROGRESS_TYPE
      ['assignment_view_trainings',
       TrainingsAssignmentViewContext.new(line_item:, user:, instructor:)]
    when LtiLineItem::PEER_REVIEW_TYPE
      ['assignment_view_peer_review',
       PeerReviewAssignmentViewContext.new(line_item:, user:, instructor:)]
    end
  end

  # Whose data the student-facing panels show: the signed-in user when a
  # session exists (top-level tab), else the Dashboard user already linked
  # to this launch's LTI identity (in-iframe, where session cookies are
  # partitioned away). Callers gate student views on this being present —
  # instructor rosters don't need it.
  # Memoized because the identity line in the lti_iframe layout reads the same
  # answer (see LtiLaunchHelper#lti_page_account) and shouldn't re-query for it.
  def launch_viewer
    @launch_viewer ||= current_user || lti_linked_user
  end

  def lti_linked_user
    return if @binding.nil?

    LtiContext.connected_user(binding_id: @binding.id,
                              user_lti_id: @lti_session.user_lti_id)
  end
end
