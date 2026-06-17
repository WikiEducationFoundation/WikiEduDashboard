# frozen_string_literal: true

class CreateFacilitatorStats < ActiveRecord::Migration[7.0]
  def change
    create_table :facilitator_stats do |t|
      t.date       :snapshot_date,           null: false
      t.integer    :user_id,                 null: false
      t.foreign_key :users, column: :user_id
      t.integer    :total_programs_count,    default: 0
      t.integer    :active_programs_count,   default: 0
      t.integer    :total_edits,             default: 0
      t.integer    :new_editors_count,       default: 0
      t.integer    :new_editors_count_with_preregistration, default: 0
      t.integer    :total_students_count,    default: 0
      t.bigint     :total_characters_added,  default: 0
      t.boolean    :active_in_last_year,     default: false
      t.timestamps

      t.index %i[snapshot_date user_id], unique: true
      t.index :user_id
    end
  end
end
