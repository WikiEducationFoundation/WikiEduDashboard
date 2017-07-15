class RemoveCacheColumnsFromArticle < ActiveRecord::Migration[5.1]
  def change
    remove_column :articles, :character_sum
    remove_column :articles, :views
    remove_column :articles, :revision_count
  end
end
