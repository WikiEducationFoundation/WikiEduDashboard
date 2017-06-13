class AddAttachmentImageToUserProfiles < ActiveRecord::Migration[4.2]
  def self.up
    change_table :user_profiles do |t|
      t.attachment :image
    end
  end

  def self.down
    remove_attachment :user_profiles, :image
  end
end
