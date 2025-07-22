class AddFirstLoginToUser < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :first_login, :datetime
  end
end
