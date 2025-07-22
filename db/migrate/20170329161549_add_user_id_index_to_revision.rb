class AddUserIdIndexToRevision < ActiveRecord::Migration[5.0]
  def change
    add_index :revisions, :user_id
  end
end
