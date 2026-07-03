# frozen_string_literal: true

require 'cgi'

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

  # Resolve via the deep-link `resource` marker (e.g. "Block:42"), validated
  # against the bound course's own gradables so a stale/forged marker can't bind
  # an arbitrary one. If a local row for that gradable already exists (e.g. from
  # SyncLtiLineItems), return it — a deep-link launch reliably carries the marker
  # but not always a scoped line-item URL, so we can't depend on the URL. Only
  # when there's no local row yet do we need the launch's URL, to create one.
  def bind_from_deep_link
    gradable = deep_link_gradable
    return if gradable.nil?

    existing = LtiLineItem.active.find_by(lti_course_binding_id: @binding.id,
                                          gradable_type: gradable.gradable_type,
                                          gradable_id: gradable.gradable_id)
    existing || bind_line_item_from_launch(gradable)
  end

  def bind_line_item_from_launch(gradable)
    lineitem_url = @lti_session.ags_lineitem_url
    return if lineitem_url.blank?

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

    # Match the raw marker and a CGI-unescaped form: the deep-link launch URL
    # carries the resource CGI-escaped (e.g. "Block%3A42"), and some launches
    # surface that escaped value rather than the clean content-item custom.
    candidates = [resource, CGI.unescape(resource)].uniq
    DeepLinkableGradables.new(@binding.course).result.find { |g| candidates.include?(g.resource) }
  end
end
