class AddTrainedToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :trainined, :boolean
  end
end
