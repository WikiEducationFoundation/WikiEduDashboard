# frozen_string_literal: true

require 'cgi'

# Resolves which LtiLineItem an `assignment_view` launch refers to, so the
# controller can render the right gradebook column's drill-down.
#
# Order of resolution:
#   1. Fast path — a line item whose `canvas_assignment_id` was captured before.
#   2. Match the launch's single line-item URL against a known local row.
#   3. Deep-link `resource` marker — only when the platform echoes the content-
#      item custom. Canvas does NOT, so this is a defensive fallback.
#   4. The launch's own AGS line item: Canvas doesn't echo our custom marker, but
#      the deep-link-created line item is TAGGED with the gradable, so read that
#      tag off it (via AGS) and bind — repointing the local row so the deep-link
#      column is the gradable's canonical one. Returns nil (=> orphan) if none apply.
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
    backfill_from_launch(scope, canvas_assignment_id) ||
      bind_from_deep_link ||
      bind_from_launch_line_item
  end

  def backfill_from_launch(scope, canvas_assignment_id)
    lineitem_url = @lti_session.ags_lineitem_url
    return if lineitem_url.blank?

    line_item = scope.find_by(lineitem_id: lineitem_url)
    return if line_item.nil?

    line_item.update!(canvas_assignment_id:) if canvas_assignment_id.present?
    line_item
  end

  # Deep-link `resource` marker path (validated against the bound course's own
  # gradables). Returns an existing local row for that gradable, else binds one
  # from the launch's line-item URL.
  def bind_from_deep_link
    gradable = deep_link_gradable
    return if gradable.nil?

    existing = active_line_item_for(gradable)
    return existing if existing

    url = @lti_session.ags_lineitem_url
    url.present? ? bind_line_item(gradable, url) : nil
  end

  # Canvas carries only the launch's own AGS lineItemId (no echoed custom). The
  # line item is tagged with the gradable, so read the tag (via AGS) and bind or
  # repoint the local row to this deep-link column — the gradable's canonical one.
  def bind_from_launch_line_item
    lineitem_url = @lti_session.ags_lineitem_url
    return if lineitem_url.blank?

    gradable = gradable_for_resource(launch_line_item_tag(lineitem_url))
    gradable && bind_line_item(gradable, lineitem_url)
  end

  def launch_line_item_tag(lineitem_url)
    LtiServiceSession.new(@binding).list_line_items
                     .find { |li| li['id'] == lineitem_url }&.dig('tag')
  rescue StandardError
    nil
  end

  def deep_link_gradable
    resource = @lti_session.deep_link_resource
    return if resource.blank?

    gradable_for_resource(resource) || gradable_for_resource(CGI.unescape(resource))
  end

  # The bound course's gradable whose `resource` marker matches, if any. The
  # course's own gradables are the only valid targets, so a stale or forged
  # marker can't bind to an arbitrary one.
  def gradable_for_resource(resource)
    return if resource.blank? || @binding.course.nil?

    DeepLinkableGradables.new(@binding.course).result.find { |g| g.resource == resource }
  end

  def active_line_item_for(gradable)
    LtiLineItem.active.find_by(lti_course_binding_id: @binding.id,
                               gradable_type: gradable.gradable_type,
                               gradable_id: gradable.gradable_id)
  end

  def bind_line_item(gradable, lineitem_url)
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
end
