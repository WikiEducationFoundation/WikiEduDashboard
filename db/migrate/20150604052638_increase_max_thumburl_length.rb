class IncreaseMaxThumburlLength < ActiveRecord::Migration
  def up
    change_column :commons_uploads, :thumburl, :string, limit: 2000
  end

  def down
    change_column :commons_uploads, :thumburl, :string, limit: 255
  end
end
