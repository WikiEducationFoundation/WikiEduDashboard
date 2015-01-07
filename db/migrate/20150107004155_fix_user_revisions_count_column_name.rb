class FixUserRevisionsCountColumnName < ActiveRecord::Migration
  def change
    rename_column :users, :revisions_count, :revision_count
  end
end
