class ChangeAlertMessageSize < ActiveRecord::Migration
  def up
    change_column :alerts, :message, :text
  end

  def down
    change_column :alerts, :message, :string
  end
end
