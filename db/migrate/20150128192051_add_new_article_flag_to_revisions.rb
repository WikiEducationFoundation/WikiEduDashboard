class AddNewArticleFlagToRevisions < ActiveRecord::Migration[4.2]
  def change
    add_column :revisions, :new_article, :boolean, :default => false
  end
end
