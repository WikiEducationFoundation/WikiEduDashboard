class AddCheckOriginToRevisionAiScores < ActiveRecord::Migration[8.1]
  def change
    add_column :revision_ai_scores, :check_origin, :string
  end
end
