class RemoveIndexTrigramsIndexByOwner < ActiveRecord::Migration[7.0]
  def change
    remove_index :trigrams, name: "index_by_owner"
  end
end
