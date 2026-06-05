# frozen_string_literal: true

# Resolves which LtiLineItem an `assignment_view` launch refers to, so the
# controller can render the right gradebook column's drill-down.
#
# Fast path: a line item whose `canvas_assignment_id` was captured on a
# previous launch. Fallback: match the launch's single line-item URL
# against a known row and backfill `canvas_assignment_id` so later launches
# hit the fast path. Last resort, for a deep-link-created assignment's first
# launch (Canvas, not us, made the AGS line item, so no local row exists yet):
# bind one from the launch's `resource` marker. Returns nil (=> orphan view)
# when none of these apply.
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
    backfill_from_launch(scope, canvas_assignment_id) || bind_from_deep_link
  end

  def backfill_from_launch(scope, canvas_assignment_id)
    lineitem_url = @lti_session.ags_lineitem_url
    return if lineitem_url.blank?

    line_item = scope.find_by(lineitem_id: lineitem_url)
    return if line_item.nil?

    line_item.update!(canvas_assignment_id:) if canvas_assignment_id.present?
    line_item
  end

  # First launch of a deep-link-created assignment: the `resource` marker
  # (e.g. "Block:42") and the launch's line-item URL together let us create
  # the local row binding that Canvas column to its Dashboard gradable. The
  # resource is validated against the bound course's own gradables, so a
  # stale or forged marker can't bind to an arbitrary gradable.
  def bind_from_deep_link
    gradable = deep_link_gradable
    lineitem_url = @lti_session.ags_lineitem_url
    return if gradable.nil? || lineitem_url.blank?

    line_item = LtiLineItem.find_or_initialize_by(
      lti_course_binding_id: @binding.id,
      gradable_type: gradable.gradable_type, gradable_id: gradable.gradable_id
    )
    line_item.lineitem_id = lineitem_url
    line_item.label = gradable.label
    line_item.archived_at = nil
    line_item.canvas_assignment_id = @lti_session.canvas_assignment_id.presence ||
                                     line_item.canvas_assignment_id
    line_item.save!
    line_item
  end

  def deep_link_gradable
    resource = @lti_session.deep_link_resource
    return if resource.blank? || @binding.course.nil?

    DeepLinkableGradables.new(@binding.course).result.find { |g| g.resource == resource }
  end
end
