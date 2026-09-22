# frozen_string_literal: true

class CreateExperimentCoursesUsers < ActiveRecord::Migration[7.0]
  def change
    create_table :experiment_courses_users do |t|
      t.string :experiment_slug, null: false
      t.integer :courses_user_id, null: false
      t.integer :status, null: false
      t.datetime :userscript_installed_at

      t.timestamps
    end

    add_index :experiment_courses_users, %i[experiment_slug courses_user_id],
              unique: true, name: 'index_experiment_courses_users_on_slug_and_courses_user'
    add_index :experiment_courses_users, :courses_user_id
  end
end
