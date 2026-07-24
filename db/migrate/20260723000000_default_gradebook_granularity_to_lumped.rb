# frozen_string_literal: true

# The integration is now deep-link-first: nothing is auto-created and the
# instructor imports columns via the Canvas Modules "Import Wikipedia
# assignments" flow. New bindings default to 'lumped' (the deep-link-first
# mode); the setup step no longer offers a gradebook-layout choice.
class DefaultGradebookGranularityToLumped < ActiveRecord::Migration[7.0]
  def change
    change_column_default :lti_course_bindings, :gradebook_granularity,
                          from: 'standard', to: 'lumped'
  end
end
