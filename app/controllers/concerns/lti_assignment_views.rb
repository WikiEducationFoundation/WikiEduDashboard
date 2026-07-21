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
    # A deep-link-created assignment launches through its own Canvas resource
    # link, so `@binding` (keyed on lms_resource_link_id) is a fresh, empty
    # binding — the course + synced line items live on the context's *bound*
    # binding. Resolve against that; fall back to the launch binding if the
    # context isn't linked to a Dashboard course yet.
    binding = @lti_session.bound_binding || @binding
    line_item = ResolveAssignmentLineItem.new(binding:, lti_session: @lti_session).result
    template, @context = assignment_view_for(line_item)
    return render 'lti_launch/assignment_view_orphan', layout: 'lti_iframe' if template.nil?

    render "lti_launch/#{template}", layout: 'lti_iframe'
  end

  # Template + view context for the resolved line item's gradable type.
  def assignment_view_for(line_item)
    instructor = @lti_session.instructor?
    case line_item&.gradable_type
    when 'Block'
      ['assignment_view',
       AssignmentViewContext.new(line_item:, user: current_user, instructor:)]
    when LtiLineItem::SETUP_TYPE
      ['assignment_view_setup', SetupAssignmentViewContext.new(line_item:, instructor:)]
    when LtiLineItem::TRAINING_PROGRESS_TYPE
      ['assignment_view_trainings',
       TrainingsAssignmentViewContext.new(line_item:, user: current_user, instructor:)]
    end
  end
end
