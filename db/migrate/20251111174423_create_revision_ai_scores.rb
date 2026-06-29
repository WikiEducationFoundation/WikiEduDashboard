class CreateRevisionAiScores < ActiveRecord::Migration[7.0]
  def change
    create_table :revision_ai_scores do |t|
      t.integer :revision_id, null: false
      t.integer :wiki_id, null: false
      t.integer :course_id, null: false
      t.integer :user_id, null: false
      t.integer :article_id
      t.datetime :revision_datetime
      t.float :avg_ai_likelihood
      t.float :max_ai_likelihood
      t.text :details
      t.string :check_type

      t.timestamps
    end

    add_index :revision_ai_scores,
        [:wiki_id, :revision_id],
        name: 'revision_ai_scores_by_wiki_rev'
  end
end
