class AddDeletedToCommonsUploads < ActiveRecord::Migration
  def change
    add_column :commons_uploads, :deleted, :boolean, :default => false
  end
end
