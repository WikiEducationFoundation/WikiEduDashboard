class RenameRevisionTimestampToDate < ActiveRecord::Migration[4.2]
  def change
    rename_column :revisions, :timestamp, :date
  end
end
