# frozen_string_literal: true
class CreateCourseUserWikiTimeslices < ActiveRecord::Migration[7.0]
  def change
    create_table :course_user_wiki_timeslices do |t|
      t.integer :course_id, null: false
      t.integer :user_id, null: false
      t.integer :wiki_id, null: false
      t.datetime :start
      t.datetime :end
      t.integer :character_sum_ms, default: 0
      t.integer :character_sum_us, default: 0
      t.integer :character_sum_draft, default: 0
      t.integer :references_count, default: 0
      t.integer :revision_count, default: 0

      t.timestamps
    end

    add_index :course_user_wiki_timeslices,
              [:course_id, :user_id, :wiki_id, :start, :end],
              unique: true,
              name: 'course_user_wiki_timeslice_by_course_user_wiki_start_and_end'
  end
end
