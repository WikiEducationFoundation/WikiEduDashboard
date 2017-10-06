class AddIthenticateIdToRevisions < ActiveRecord::Migration[4.2]
  def change
    add_column :revisions, :ithenticate_id, :integer, default: nil
  end
end
