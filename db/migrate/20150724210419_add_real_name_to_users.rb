class AddRealNameToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :real_name, :string
  end
end
