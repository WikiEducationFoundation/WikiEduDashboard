class RenameRevisionTimestampToDate < ActiveRecord::Migration
  def change
    rename_column :revisions, :timestamp, :date
  end
end
