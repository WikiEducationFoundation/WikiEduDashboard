class AddGreeterToUsers < ActiveRecord::Migration
  def change
    add_column :users, :greeter, :boolean, default: false
  end
end
