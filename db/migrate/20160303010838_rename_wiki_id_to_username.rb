class RenameWikiIdToUsername < ActiveRecord::Migration
  def change
    rename_column :users, :wiki_id, :username
  end
end
