class AddDetailsToAlerts < ActiveRecord::Migration[5.1]
  def change
    add_column :alerts, :details, :text
  end
end
