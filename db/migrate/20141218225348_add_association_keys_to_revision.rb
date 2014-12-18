class AddAssociationKeysToRevision < ActiveRecord::Migration
  def change
    add_column :revisions, :user_id, :integer
    add_column :revisions, :article_id, :integer
  end
end
