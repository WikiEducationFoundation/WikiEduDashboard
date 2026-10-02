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
    # Before the contexts are built: a submission launch narrows them to one student.
    @focus_user = submission_focus_user(binding) if params[:submission].present?
    line_item = ResolveAssignmentLineItem.new(binding:, lti_session: @lti_session,
                                              resource_marker: params[:resource]).result
    template, @context = assignment_view_for(line_item)
    return render_submission_placeholder(binding) if submission_fallback?(template)
    return render 'lti_launch/assignment_view_orphan', layout: 'lti_iframe' if template.nil?

    render "lti_launch/#{template}", layout: 'lti_iframe'
  end

  # A submission launch we can't render as one student's work: the marker named
  # nobody we may show them, or the column itself didn't resolve. Either way the
  # placeholder is a better answer than the orphan view, which talks about the
  # assignment rather than the submission the instructor opened.
  def submission_fallback?(template)
    params[:submission].present? && (@focus_user.nil? || template.nil?)
  end

  # Which student a submission launch is about — the `submission` marker on the URL
  # we hand Canvas as the submission's own (LtiScorePayload#submission_launch_url)
  # carries their LMS user id.
  #
  # Instructors may be shown anyone on the roster; a student may only ever be shown
  # their own work, so a marker naming somebody else resolves to nobody rather than
  # opening another student's sandboxes. Nil also covers the URLs Canvas stored
  # before the marker named a student (`submission=1`) and members who have since
  # left the course; all three land on the student-less placeholder.
  def submission_focus_user(binding)
    return if binding.nil?

    target = LtiContext.find_by(lti_course_binding_id: binding.id,
                                user_lti_id: params[:submission])
    return if target.nil? || target.user.nil?
    return target.user if @lti_session.instructor?

    target.user_lti_id == @lti_session.user_lti_id ? target.user : nil
  end

  # A launch from a student's submission in Canvas — SpeedGrader or the submission
  # page — that we can't tie to a student on this roster. Canvas's own fallback for
  # an assignment whose grade arrived by AGS is a bare "No Preview Available"; say
  # what is actually going on and point at the Dashboard instead.
  def render_submission_placeholder(binding)
    @submission_course = binding&.course
    render 'lti_launch/assignment_view_submission', layout: 'lti_iframe'
  end

  # Template + view context for the resolved line item's gradable type.
  #
  # `focus_user` narrows the instructor roster to one student for a submission
  # launch; it is nil for every other launch, which leaves the roster whole.
  def assignment_view_for(line_item)
    instructor = @lti_session.instructor?
    focus_user = @focus_user
    # Per-student panels describe the student the submission is about; with no
    # focus that's whoever launched.
    user = focus_user || launch_viewer
    case line_item&.gradable_type
    when 'Block'
      ['assignment_view', AssignmentViewContext.new(line_item:, user:, instructor:, focus_user:)]
    when LtiLineItem::SETUP_TYPE
      ['assignment_view_setup',
       SetupAssignmentViewContext.new(line_item:, instructor:, user:, focus_user:)]
    when LtiLineItem::TRAINING_PROGRESS_TYPE
      ['assignment_view_trainings',
       TrainingsAssignmentViewContext.new(line_item:, user:, instructor:, focus_user:)]
    when LtiLineItem::PEER_REVIEW_TYPE
      ['assignment_view_peer_review',
       PeerReviewAssignmentViewContext.new(line_item:, user:, instructor:, focus_user:)]
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
