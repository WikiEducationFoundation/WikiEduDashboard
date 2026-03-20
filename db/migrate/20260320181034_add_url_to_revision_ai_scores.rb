class AddUrlToRevisionAiScores < ActiveRecord::Migration[8.1]
  def change
    add_column :revision_ai_scores, :url, :string
  end
end
