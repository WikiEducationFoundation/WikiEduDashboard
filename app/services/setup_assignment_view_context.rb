# frozen_string_literal: true

# Bundles the data for the in-Canvas assignment view of the "Wikipedia
# account" (WikipediaSetup) gradebook column: which of the Canvas course's
# students have connected a Wikipedia account. Unlike the Block-backed
# views, not-yet-linked memberships matter here — they are exactly the rows
# the instructor opens this column to find, so they're listed (first) even
# though all we can show for them is the LMS-supplied name or an opaque id.
class SetupAssignmentViewContext
  Row = Struct.new(:name, :connected, keyword_init: true) do
    def connected?
      connected
    end
  end

  attr_reader :line_item

  def initialize(line_item:, instructor:)
    @line_item = line_item
    @instructor = instructor
    @binding = line_item.lti_course_binding
  end

  def instructor?
    @instructor
  end

  def title
    @line_item.label
  end

  def rows
    @rows ||= student_contexts.map do |context|
      Row.new(name: display_name(context), connected: context.linked?)
    end
  end

  def connected_count
    rows.count(&:connected?)
  end

  def total_count
    rows.size
  end

  private

  # Every student membership (linked or not), not-yet-connected first —
  # those are the actionable rows — then by display name.
  def student_contexts
    @binding.lti_contexts.reject(&:instructor?)
            .sort_by { |context| [context.linked? ? 1 : 0, display_name(context).downcase] }
  end

  # Anonymized-mode launches carry no LMS name, so a linked row falls back
  # to the Wikipedia username and an unlinked one to the opaque LMS user id
  # (making those legible is a follow-up in docs/canvas_integration_todos.md).
  def display_name(context)
    context.name.presence || context.user&.username || context.user_lti_id
  end
end
