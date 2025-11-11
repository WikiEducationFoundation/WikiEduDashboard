class CreateRevisionAiScores < ActiveRecord::Migration[7.0]
  def change
    create_table :revision_ai_scores do |t|
      t.integer :revision_id, null: false
      t.integer :wiki_id, null: false
      t.integer :course_id, null: false
      t.integer :user_id, null: false
      t.integer :article_id
      t.datetime :date
      t.float :avg_ai_likelihood
      t.float :max_ai_likelihood
      t.text :details

      t.timestamps
    end
  end
end
