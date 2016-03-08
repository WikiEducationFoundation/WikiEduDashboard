class CreateSurveys < ActiveRecord::Migration
  def change
    # drop_table :surveys
    create_table :surveys do |t|
      t.string :name
      t.references :rapidfire_question_groups, index: true
      t.timestamps null: false
    end
  end
end
