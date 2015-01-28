class AddNewArticleFlagToRevisions < ActiveRecord::Migration
  def change
    add_column :revisions, :new_article, :boolean, :default => false
  end
end
