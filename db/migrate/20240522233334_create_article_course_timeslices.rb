class CreateArticleCourseTimeslices < ActiveRecord::Migration[7.0]
  def change
    create_table :article_course_timeslices do |t|
      t.integer :article_course_id, null: false
      t.datetime :start
      t.datetime :end
      t.integer :last_mw_rev_id
      t.integer :character_sum, default: 0
      t.integer :references_count, default: 0
      t.text :user_ids, default: ""

      t.timestamps
    end
  end
end
