# frozen_string_literal: true

# Records the Canvas-side assignment id for a gradebook line item so an
# `assignment_view` LTI launch (which carries `$Canvas.assignment.id` in
# its custom claim) can be routed back to the matching LtiLineItem.
#
# Nullable: older line items have no value until an assignment_view launch
# backfills it, and the lumped TrainingProgress line item never gets one.
# Stored as a string because Canvas ids can be globally prefixed for
# cross-shard installs.
class AddCanvasAssignmentIdToLtiLineItems < ActiveRecord::Migration[7.0]
  def change
    add_column :lti_line_items, :canvas_assignment_id, :string

    add_index :lti_line_items,
              %i[lti_course_binding_id canvas_assignment_id],
              unique: true,
              name: 'index_lti_line_items_on_binding_and_canvas_assignment'
  end
end
