class AddConditionalsToQuestions < ActiveRecord::Migration
  def change
    add_column :rapidfire_questions, :conditionals, :text
  end
end
