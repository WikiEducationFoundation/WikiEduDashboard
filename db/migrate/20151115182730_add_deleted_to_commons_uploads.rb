class AddDeletedToCommonsUploads < ActiveRecord::Migration[4.2]
  def change
    add_column :commons_uploads, :deleted, :boolean, :default => false
  end
end
