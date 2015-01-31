class RemoveFirstNameAndLastNameFromUsers < ActiveRecord::Migration
  def change
    remove_column :users, :first_name
    remove_column :users, :last_name
  end
end
