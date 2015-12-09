class AddOnboardedToUser < ActiveRecord::Migration
  def change
    add_column :users, :onboarded, :boolean, default: false
  end
end
