class AddPlaceholderTextToQuestion < ActiveRecord::Migration
  def change
    add_column :rapidfire_questions, :placeholder_text, :string
  end
end
