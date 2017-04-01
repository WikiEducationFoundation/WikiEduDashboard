class AddAttributesToUserProfiles < ActiveRecord::Migration[5.0]
  def change
    add_column :user_profiles, :location, :string
    add_column :user_profiles, :work_status, :string
  end
end
