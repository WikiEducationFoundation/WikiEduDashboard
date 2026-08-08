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
#     of the course's gradables. A pending reservation (lineitem_id NULL, created
#     by the deep-link picker before the column existed) is adopted here — the
#     same row gets the discovered lineitem_id — rather than duplicated.
#   - Soft-archive locally (set archived_at) the rows whose gradable has left the
#     timeline, or whose Canvas column has gone. We never DELETE from LTIAAS —
#     that would erase the corresponding Canvas gradebook column and its scores.
#   - End pending reservations still unbound after PENDING_EXPIRY: the picker form
#     never reached Canvas, and an undying reservation would block the gradable
#     from ever being imported. A reservation that created its own row is
#     destroyed; one that revived an archived row is rolled back to that archived
#     state (see LtiLineItem#expire_reservation!).
#
# Labels are not pushed: the instructor named the assignment at import time and
# Canvas owns it from there. Renaming a block updates the local row's label (what
# the Dashboard's own views show) and nothing in Canvas.
#
# A binding without a stored serviceKey, or without a bound course, is a no-op.
class SyncLtiLineItems
  # How long a pending reservation may stay unbound before it's judged
  # abandoned. The deep-link form auto-submits within seconds and the
  # discovery worker fires 2 minutes after it's returned, so a reservation
  # still pending after 30 minutes — several sync cycles later — means the
  # form never reached Canvas (closed modal, abandoned tab), not that
  # discovery is merely slow.
  PENDING_EXPIRY = 30.minutes

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

  # `reserved_prior_state` is cleared here: this row now maps a real Canvas
  # column, so the archived state a reservation may have overwritten is
  # superseded and must not be restorable by a later expiry.
  def bind_discovered_line_item(gradable, canvas_item, existing)
    line_item = existing[[gradable.gradable_type, gradable.gradable_id]] ||
                LtiLineItem.new(lti_course_binding: @binding,
                                gradable_type: gradable.gradable_type,
                                gradable_id: gradable.gradable_id)
    line_item.update!(lineitem_id: canvas_item['id'], label: gradable.label,
                      archived_at: nil, reserved_prior_state: nil)
  end

  # A pending row is a deep-link reservation, not a stale column — no Canvas
  # line item backs it yet, so archiving it is meaningless and would reopen
  # the gradable to a duplicate import. Keep a fresh one holding its slot and
  # expire an abandoned one; there is no Canvas-side data behind an unbound
  # reservation, so the never-delete rule doesn't apply to the reservation
  # itself (it still applies to whatever the reservation revived).
  def archive_stale(existing, kept_keys)
    kept = kept_keys.to_set
    existing.each_value do |line_item|
      next if kept.include?([line_item.gradable_type, line_item.gradable_id])
      next expire_if_abandoned(line_item) if line_item.pending?
      next if line_item.archived?

      line_item.archive!
    end
  end

  # updated_at, not created_at: reserving via an archived row's revival only
  # touches updated_at, and an expiry clock that predates the reservation
  # could destroy it before its form's column is discovered. The destroy is
  # re-checked under a row lock (see LtiLineItem#expire_reservation!) because
  # this run's `existing` snapshot predates the remote fetch — a launch can
  # adopt the reservation in between.
  def expire_if_abandoned(line_item)
    line_item.expire_reservation!(older_than: PENDING_EXPIRY.ago)
  end
end
