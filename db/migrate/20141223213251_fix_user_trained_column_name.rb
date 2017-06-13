class FixUserTrainedColumnName < ActiveRecord::Migration[4.2]
  def change
    rename_column :users, :trainined, :trained
  end
end
