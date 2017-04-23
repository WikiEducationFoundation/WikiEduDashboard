class ChangeAlertMessageSize < ActiveRecord::Migration[4.2]
  def up
    change_column :alerts, :message, :text
  end

  def down
    change_column :alerts, :message, :string
  end
end
