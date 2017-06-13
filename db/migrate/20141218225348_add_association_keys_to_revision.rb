class AddAssociationKeysToRevision < ActiveRecord::Migration[4.2]
  def change
    add_column :revisions, :user_id, :integer
    add_column :revisions, :article_id, :integer
  end
end
