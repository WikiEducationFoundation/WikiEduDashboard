class AddTrainedToUsers < ActiveRecord::Migration
  def change
    add_column :users, :trainined, :boolean
  end
end
