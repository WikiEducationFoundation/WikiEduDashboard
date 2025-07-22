class AddTimestampRemoveDateFromRevision < ActiveRecord::Migration[4.2]
  def change
    remove_column :revisions, :date
    add_column :revisions, :timestamp, :datetime
  end

  # def up
  #   change_column :revisions, :date, :datetime
  # end

  # def down
  #   change_column :revisions, :date, :date
  # end
end
