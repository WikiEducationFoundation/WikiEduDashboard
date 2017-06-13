class RemoveRevisionMwRevIndex < ActiveRecord::Migration[5.1]
  def change
    remove_index :revisions, name: 'index_revisions_on_mw_rev_id'
  end
end
