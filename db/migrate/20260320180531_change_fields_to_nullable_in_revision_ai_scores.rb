class ChangeFieldsToNullableInRevisionAiScores < ActiveRecord::Migration[8.1]
  def change
    change_column_null :revision_ai_scores, :course_id, true
    change_column_null :revision_ai_scores, :revision_id, true
    change_column_null :revision_ai_scores, :wiki_id, true
    change_column_null :revision_ai_scores, :user_id, true
  end
end
