class AddResolvedToAlerts < ActiveRecord::Migration[5.0]
  def change
    add_column :alerts, :resolved, :boolean, default: false
  end
end
