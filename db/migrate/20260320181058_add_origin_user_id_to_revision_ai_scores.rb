class AddOriginUserIdToRevisionAiScores < ActiveRecord::Migration[8.1]
  def change
    add_column :revision_ai_scores, :origin_user_id, :integer
  end
end
