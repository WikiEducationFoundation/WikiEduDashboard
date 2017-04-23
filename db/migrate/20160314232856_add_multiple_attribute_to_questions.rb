class AddMultipleAttributeToQuestions < ActiveRecord::Migration[4.2]
  def change
    add_column :rapidfire_questions, :multiple, :boolean, :default => false
  end
end
