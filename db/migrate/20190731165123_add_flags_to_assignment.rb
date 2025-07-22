class AddFlagsToAssignment < ActiveRecord::Migration[5.2]
  def change
    add_column :assignments, :flags, :text
  end
end
