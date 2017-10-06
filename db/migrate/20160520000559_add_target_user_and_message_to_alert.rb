class AddTargetUserAndMessageToAlert < ActiveRecord::Migration[4.2]
  def change
    add_column :alerts, :message, :string
    add_reference :alerts, :target_user, index: true
  end
end
