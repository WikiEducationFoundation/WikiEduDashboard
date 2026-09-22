# frozen_string_literal: true

# Extends the pre-existing LtiContext to:
#   - associate with an LtiCourseBinding (replacing the composed
#     `context_id` string identifier going forward)
#   - capture the LMS roles NRPS supplies, so staff can be told from students
#   - track when the User association was actually established (`linked_at`)
#   - record the LMS's own membership status (`lms_membership_status`), so a
#     member Canvas has removed or suspended is visible to staff
#
# Anonymized posture: no LMS-supplied name or email is stored. NRPS gives us the
# opaque LTI user id, roles, and membership status and nothing else; identity
# comes from the student's own Wikipedia OAuth, so there is no email-based
# auto-linking to support and no PII to hold.
#
# `user_id` becomes nullable: NRPS roster sync may discover Canvas
# members before they personally launch from Canvas + complete Wikipedia
# OAuth. Those rows have user_id=NULL until the student links.
#
# The two unique indexes make the map 1:1 in both directions within a binding.
# (binding, user_id) is the one that stops two Canvas members from resolving to a
# single Wikipedia account, which would post the same progress at both of their
# gradebook rows. MySQL treats NULLs as distinct, so it constrains neither the
# not-yet-connected members (user_id NULL) nor the legacy rows this table already
# holds (lti_course_binding_id NULL).
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
    add_column :lti_contexts, :roles, :text
    add_column :lti_contexts, :linked_at, :datetime
    # Last NRPS-reported membership status (Active/Inactive/Deleted), refreshed
    # on every roster sync. Read-only reconciliation state: it flags "removed
    # in Canvas" members for staff, and never drives automatic disenrollment.
    add_column :lti_contexts, :lms_membership_status, :string

    add_index :lti_contexts, %i[user_lti_id lti_course_binding_id],
              unique: true,
              name: 'index_lti_contexts_on_user_lti_id_and_binding'
    add_index :lti_contexts, %i[lti_course_binding_id user_id],
              unique: true,
              name: 'index_lti_contexts_on_binding_and_user'
  end
end
