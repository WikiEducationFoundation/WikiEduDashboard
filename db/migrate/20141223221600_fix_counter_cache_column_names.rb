class FixCounterCacheColumnNames < ActiveRecord::Migration
  def change
    rename_column :users, :revision_count, :revisions_count
    rename_column :articles, :revision_count, :revisions_count
  end
end
