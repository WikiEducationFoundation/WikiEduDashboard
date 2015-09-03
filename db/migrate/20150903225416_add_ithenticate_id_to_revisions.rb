class AddIthenticateIdToRevisions < ActiveRecord::Migration
  def change
    add_column :revisions, :ithenticate_id, :integer, default: nil
  end
end
