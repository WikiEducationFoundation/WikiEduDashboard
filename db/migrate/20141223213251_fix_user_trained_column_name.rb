class FixUserTrainedColumnName < ActiveRecord::Migration
  def change
    rename_column :users, :trainined, :trained
  end
end
