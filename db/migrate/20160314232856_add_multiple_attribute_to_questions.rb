class AddMultipleAttributeToQuestions < ActiveRecord::Migration
  def change
    add_column :rapidfire_questions, :multiple, :boolean, :default => false
  end
end
