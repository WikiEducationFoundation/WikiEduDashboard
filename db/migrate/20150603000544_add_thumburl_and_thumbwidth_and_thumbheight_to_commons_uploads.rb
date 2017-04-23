class AddThumburlAndThumbwidthAndThumbheightToCommonsUploads < ActiveRecord::Migration[4.2]
  def change
    add_column :commons_uploads, :thumburl, :string
    add_column :commons_uploads, :thumbwidth, :string
    add_column :commons_uploads, :thumbheight, :string
  end
end
