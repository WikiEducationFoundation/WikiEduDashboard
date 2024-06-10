class CreateCourseUserWikiTimeslices < ActiveRecord::Migration[7.0]
  def change
    create_table :course_user_wiki_timeslices do |t|
      t.integer :course_user_id, null: false
      t.integer :wiki_id, null:false
      t.datetime :start
      t.datetime :end
      t.integer :last_mw_rev_id
      t.integer :total_uploads, default: 0
      t.integer :character_sum_ms, default: 0
      t.integer :character_sum_us, default: 0
      t.integer :character_sum_draft, default: 0
      t.integer :references_count, default: 0
      t.integer :revision_count, default: 0

      t.timestamps
    end
  end
end
