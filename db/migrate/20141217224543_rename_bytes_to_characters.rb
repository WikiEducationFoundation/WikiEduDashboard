class RenameBytesToCharacters < ActiveRecord::Migration[4.2]
  def self.up
    rename_column :revisions, :bytes, :characters
  end
end
