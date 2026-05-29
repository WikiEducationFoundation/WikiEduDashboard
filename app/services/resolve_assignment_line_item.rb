# frozen_string_literal: true

# Resolves which LtiLineItem an `assignment_view` launch refers to, so the
# controller can render the right gradebook column's drill-down.
#
# Fast path: a line item whose `canvas_assignment_id` was captured on a
# previous launch. Fallback: match the launch's single line-item URL
# against a known row and backfill `canvas_assignment_id` so later launches
# hit the fast path. Returns nil (=> orphan view) when neither matches.
class ResolveAssignmentLineItem
  attr_reader :result

  def initialize(binding:, lti_session:)
    @binding = binding
    @lti_session = lti_session
    @result = perform
  end

  private

  def perform
    scope = LtiLineItem.active.where(lti_course_binding_id: @binding.id)
    canvas_assignment_id = @lti_session.canvas_assignment_id
    if canvas_assignment_id.present?
      found = scope.find_by(canvas_assignment_id:)
      return found if found
    end
    backfill_from_launch(scope, canvas_assignment_id)
  end

  def backfill_from_launch(scope, canvas_assignment_id)
    lineitem_url = @lti_session.ags_lineitem_url
    return if lineitem_url.blank?

    line_item = scope.find_by(lineitem_id: lineitem_url)
    return if line_item.nil?

    line_item.update!(canvas_assignment_id:) if canvas_assignment_id.present?
    line_item
  end
end
