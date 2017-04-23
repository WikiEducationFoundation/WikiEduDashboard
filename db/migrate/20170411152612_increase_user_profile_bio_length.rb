class IncreaseUserProfileBioLength < ActiveRecord::Migration[5.0]
  def up
    change_column :user_profiles, :bio, :text
  end

  def down
    hange_column :user_profiles, :bio, :string
  end
end
