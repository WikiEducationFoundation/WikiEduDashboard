class DropRevisionsTable < ActiveRecord::Migration[7.0]
  def change
    drop_table :revisions
  end
end
