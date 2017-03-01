class AddAttachmentImageToUserProfiles < ActiveRecord::Migration
  def self.up
    change_table :user_profiles do |t|
      t.attachment :image
    end
  end

  def self.down
    remove_attachment :user_profiles, :image
  end
end
