class RenameQuestionGroupConditionalsCohortIdColumn < ActiveRecord::Migration[5.0]
  def change
    rename_column :question_group_conditionals, :cohort_id, :campaign_id
  end
end
