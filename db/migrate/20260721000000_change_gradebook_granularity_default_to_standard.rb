# frozen_string_literal: true

# 'standard' is the new recommended gradebook layout: the trainings roll-up
# column plus one auto-created column per exercise block. Existing bindings
# keep their stored value ('lumped' rows now mean the manual-exercise-columns
# mode, which matches how they actually behaved).
class ChangeGradebookGranularityDefaultToStandard < ActiveRecord::Migration[7.0]
  def change
    change_column_default :lti_course_bindings, :gradebook_granularity,
                          from: 'lumped', to: 'standard'
  end
end
