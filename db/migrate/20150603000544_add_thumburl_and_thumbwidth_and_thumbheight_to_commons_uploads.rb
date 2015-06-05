class AddThumburlAndThumbwidthAndThumbheightToCommonsUploads < ActiveRecord::Migration
  def change
    add_column :commons_uploads, :thumburl, :string
    add_column :commons_uploads, :thumbwidth, :string
    add_column :commons_uploads, :thumbheight, :string
  end
end
