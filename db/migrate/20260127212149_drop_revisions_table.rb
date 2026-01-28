class DropRevisionsTable < ActiveRecord::Migration[7.1]
  def change
    drop_table :revisions
  end
end
