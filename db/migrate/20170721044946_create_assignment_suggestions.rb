class CreateAssignmentSuggestions < ActiveRecord::Migration[5.1]
  def change
    create_table :assignment_suggestions do |t|
      t.text :text
      t.references :assignment

      t.timestamps
    end
  end
end
