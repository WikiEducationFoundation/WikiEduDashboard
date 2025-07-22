class AddEmailPreferencesToUserProfile < ActiveRecord::Migration[5.2]
  def change
    add_column :user_profiles, :email_preferences, :text
  end
end
