class AddOnboardedToUser < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :onboarded, :boolean, default: false
  end
end
