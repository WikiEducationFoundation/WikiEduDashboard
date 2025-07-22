class AddUserIdToAssignmentSuggestion < ActiveRecord::Migration[5.1]
  def change
    add_column :assignment_suggestions, :user_id, :integer, references: :users
  end
end
