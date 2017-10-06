class AddConditionalsToQuestions < ActiveRecord::Migration[4.2]
  def change
    add_column :rapidfire_questions, :conditionals, :text
  end
end
