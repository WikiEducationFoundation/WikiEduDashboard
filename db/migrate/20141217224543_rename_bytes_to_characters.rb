class RenameBytesToCharacters < ActiveRecord::Migration
  def self.up
    rename_column :revisions, :bytes, :characters
  end
end
