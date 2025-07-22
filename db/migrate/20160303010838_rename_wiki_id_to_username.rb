class RenameWikiIdToUsername < ActiveRecord::Migration[4.2]
  def change
    rename_column :users, :wiki_id, :username
  end
end
