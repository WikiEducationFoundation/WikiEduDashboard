class AddMwRevIdIndexToRevisions < ActiveRecord::Migration[5.0]
  def change
    add_index :revisions, :mw_rev_id
  end
end
