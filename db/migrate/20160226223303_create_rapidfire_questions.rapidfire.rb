# This migration comes from rapidfire (originally 20130502195310)
class CreateRapidfireQuestions < ActiveRecord::Migration
  def change
    create_table :rapidfire_questions do |t|
      t.references :question_group
      t.string  :type
      t.string  :question_text
      t.integer :position
      t.text :answer_options
      t.text :validation_rules

      t.timestamps
    end
    add_index :rapidfire_questions, :question_group_id
  end
end
