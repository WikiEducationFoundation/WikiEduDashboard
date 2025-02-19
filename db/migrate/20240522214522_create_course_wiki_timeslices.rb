# frozen_string_literal: true
class CreateCourseWikiTimeslices < ActiveRecord::Migration[7.0]
  def change
    create_table :course_wiki_timeslices do |t|
      t.integer :course_id, null: false
      t.integer :wiki_id, null: false
      t.datetime :start
      t.datetime :end
      t.integer :character_sum, default: 0
      t.integer :references_count, default: 0
      t.integer :revision_count, default: 0
      t.text :stats, limit: 65535
      t.datetime :last_mw_rev_datetime
      t.boolean :needs_update, default: false

      t.timestamps
    end

    add_index :course_wiki_timeslices,
              [:course_id, :wiki_id, :start, :end],
              unique: true,
              name: 'course_wiki_timeslice_by_course_wiki_start_and_end'
  end
end
