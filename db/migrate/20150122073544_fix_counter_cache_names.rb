class FixCounterCacheNames < ActiveRecord::Migration[4.2]
  def change
    rename_column :users, :revisions_count, :revision_count
    rename_column :articles, :revisions_count, :revision_count
  end
end
