class AddUserIdIndexToCommonsUploads < ActiveRecord::Migration[5.0]
  def change
    add_index :commons_uploads, :user_id
  end
end
