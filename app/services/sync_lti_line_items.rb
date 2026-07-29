# frozen_string_literal: true

# Reconciles LTIAAS gradebook line items for one LtiCourseBinding against
# the bound Dashboard course's timeline.
#
# The integration is deep-link-first: the Dashboard never creates a Canvas
# gradebook column. The instructor imports the ones they want through the Canvas
# Modules "Import Wikipedia assignments" flow, and this service DISCOVERS them —
# each is tagged with its gradable's resource marker — and binds a local row, so
# grade sync and the assignment drill-downs resolve without waiting for each
# column to be launched.
#
# Line-item lifecycle:
#   - Bind (or re-bind) a local row for every Canvas column whose tag matches one
#     of the course's gradables.
#   - Soft-archive locally (set archived_at) the rows whose gradable has left the
#     timeline, or whose Canvas column has gone. We never DELETE from LTIAAS —
#     that would erase the corresponding Canvas gradebook column and its scores.
#
# Labels are not pushed: the instructor named the assignment at import time and
# Canvas owns it from there. Renaming a block updates the local row's label (what
# the Dashboard's own views show) and nothing in Canvas.
#
# A binding without a stored serviceKey, or without a bound course, is a no-op.
class SyncLtiLineItems
  attr_reader :binding

  def initialize(binding)
    @binding = binding
    perform
  end

  private

  def perform
    return if @binding.course.nil?
    return if @binding.ltiaas_service_credentials.blank?

    @service = LtiServiceSession.new(@binding)
    existing = LtiLineItem.where(lti_course_binding_id: @binding.id)
                          .index_by { |li| [li.gradable_type, li.gradable_id] }
    archive_stale(existing, discover_deep_linked_columns(existing))
  end

  # Find the columns the instructor imported — each tagged with its gradable's
  # resource marker — and bind a local row (creating or reviving). Returns the
  # bound gradable keys so archive_stale knows what to keep.
  def discover_deep_linked_columns(existing)
    by_tag = @service.list_line_items.index_by { |item| item['tag'] }
    DeepLinkableGradables.new(@binding.course).result.filter_map do |gradable|
      canvas_item = by_tag[gradable.resource]
      next unless canvas_item

      bind_discovered_line_item(gradable, canvas_item, existing)
      [gradable.gradable_type, gradable.gradable_id]
    end
  end

  def bind_discovered_line_item(gradable, canvas_item, existing)
    line_item = existing[[gradable.gradable_type, gradable.gradable_id]] ||
                LtiLineItem.new(lti_course_binding: @binding,
                                gradable_type: gradable.gradable_type,
                                gradable_id: gradable.gradable_id)
    line_item.update!(lineitem_id: canvas_item['id'],
                      label: gradable.label, archived_at: nil)
  end

  def archive_stale(existing, kept_keys)
    kept = kept_keys.to_set
    existing.each_value do |line_item|
      key = [line_item.gradable_type, line_item.gradable_id]
      next if kept.include?(key) || line_item.archived?

      line_item.archive!
    end
  end
end
