class AddRegisteredAtToUser < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :registered_at, :datetime
  end
end
