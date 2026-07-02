# frozen_string_literal: true

# Extends LtiContext to:
#   - associate with an LtiCourseBinding (replacing the composed
#     `context_id` string identifier going forward)
#   - capture NRPS-supplied profile info (email, name, roles) so we can
#     auto-link by email and surface members who haven't completed
#     Wikipedia OAuth yet
#   - track when the User association was actually established
#     (`linked_at`)
#
# `user_id` becomes nullable: NRPS roster sync may discover Canvas
# members before they personally launch from Canvas + complete Wikipedia
# OAuth. Those rows have user_id=NULL until the student links.
#
# The legacy `context_id` column stays in place for one PR for
# safety; it will be dropped in a follow-up after the new flow is in.
class AddBindingFieldsToLtiContexts < ActiveRecord::Migration[8.1]
  def change
    change_column_null :lti_contexts, :user_id, true
    change_column_null :lti_contexts, :context_id, true

    add_reference :lti_contexts, :lti_course_binding,
                  null: true,
                  foreign_key: { on_delete: :cascade },
                  type: :integer,
                  index: false
    add_column :lti_contexts, :email, :string
    add_column :lti_contexts, :name, :string
    add_column :lti_contexts, :roles, :text
    add_column :lti_contexts, :linked_at, :datetime

    add_index :lti_contexts, %i[user_lti_id lti_course_binding_id],
              unique: true,
              name: 'index_lti_contexts_on_user_lti_id_and_binding'
  end
end
