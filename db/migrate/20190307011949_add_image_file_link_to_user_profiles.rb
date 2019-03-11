class AddImageFileLinkToUserProfiles < ActiveRecord::Migration[5.2]
  def change
    add_column :user_profiles, :image_file_link, :string
  end
end
