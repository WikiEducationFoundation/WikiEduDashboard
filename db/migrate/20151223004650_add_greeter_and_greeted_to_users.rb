class AddGreeterAndGreetedToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :greeted, :boolean, default: false
    add_column :users, :greeter, :boolean, default: false
  end
end
