# frozen_string_literal: true

# Records which LTI version the binding's launches speak. Existing rows all
# came from LTI 1.3 launches (the only kind the integration accepted before
# legacy support), hence the default. Legacy (LTI 1.1) launches, which the
# Dashboard terminates itself, record "1.2.0" — LTIAAS's label for a 1.1
# launch, kept so the version means the same thing whichever terminator
# produced it — and are refreshed on every launch like the other snapshot
# fields.
#
# The column is what excludes a legacy binding from the NRPS/AGS workers by
# version rather than by the accident of never having stored service
# credentials, and what later makes an institution's migration to 1.3
# trackable per binding.
class AddLtiVersionToLtiCourseBindings < ActiveRecord::Migration[7.0]
  def change
    add_column :lti_course_bindings, :lti_version, :string, null: false, default: '1.3.0'
  end
end
