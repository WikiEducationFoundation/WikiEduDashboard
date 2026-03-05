# frozen_string_literal: true

class CreateSurveyCompletionTimes < ActiveRecord::Migration[7.0]
  def change
    create_table :survey_completion_times do |t|
      t.integer :survey_id, null: false
      t.integer :user_id, null: false
      t.integer :survey_notification_id
      t.datetime :started_at, null: false
      t.datetime :completed_at
      t.integer :duration_in_seconds

      t.timestamps
    end

    add_index :survey_completion_times, :survey_id
    add_index :survey_completion_times, :user_id
    add_index :survey_completion_times, %i[survey_id user_id]
  end
end
