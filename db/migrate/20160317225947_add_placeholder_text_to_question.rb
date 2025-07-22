class AddPlaceholderTextToQuestion < ActiveRecord::Migration[4.2]
  def change
    add_column :rapidfire_questions, :placeholder_text, :string
  end
end
