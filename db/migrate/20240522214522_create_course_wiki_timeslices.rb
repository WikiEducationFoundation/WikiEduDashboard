class CreateCourseWikiTimeslices < ActiveRecord::Migration[7.0]
  def change
    create_table :course_wiki_timeslices do |t|
      t.integer :course_wiki_id, null: false
      t.datetime :start
      t.datetime :end
      t.integer :last_mw_rev_id
      t.integer :character_sum, default: 0
      t.integer :references_count, default: 0
      t.integer :revision_count, default: 0
      t.integer :upload_count, default: 0
      t.integer :uploads_in_use_count, default: 0
      t.integer :upload_usages_count, default: 0

      t.timestamps
    end
  end
end
