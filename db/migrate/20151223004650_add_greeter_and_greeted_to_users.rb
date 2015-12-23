class AddGreeterAndGreetedToUsers < ActiveRecord::Migration
  def change
    add_column :users, :greeted, :boolean, default: false
    add_column :users, :greeter, :boolean, default: false
  end
end
