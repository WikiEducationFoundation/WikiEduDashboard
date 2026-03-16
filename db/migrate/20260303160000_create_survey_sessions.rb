# frozen_string_literal: true

class CreateSurveySessions < ActiveRecord::Migration[7.0]
  def change
    create_table :survey_sessions do |t|
      t.integer :survey_id, null: false
      t.integer :user_id, null: false
      t.integer :survey_notification_id
      t.datetime :started_at, null: false
      t.datetime :completed_at


      t.timestamps
    end

    add_index :survey_sessions, :user_id
    add_index :survey_sessions, %i[survey_id user_id]
  end
end
