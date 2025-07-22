class RemoveFirstNameAndLastNameFromUsers < ActiveRecord::Migration[4.2]
  def change
    remove_column :users, :first_name
    remove_column :users, :last_name
  end
end
