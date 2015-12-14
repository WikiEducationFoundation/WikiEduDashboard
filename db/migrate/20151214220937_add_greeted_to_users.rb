class AddGreetedToUsers < ActiveRecord::Migration
  def change
    add_column :users, :greeted, :boolean, default: false
  end
end
