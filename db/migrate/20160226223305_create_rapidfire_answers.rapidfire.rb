# This migration comes from rapidfire (originally 20130502195504)
class CreateRapidfireAnswers < ActiveRecord::Migration[4.2]
  def change
    create_table :rapidfire_answers do |t|
      t.references :answer_group
      t.references :question
      t.text :answer_text

      t.timestamps
    end
    add_index :rapidfire_answers, :answer_group_id
    add_index :rapidfire_answers, :question_id
  end
end
