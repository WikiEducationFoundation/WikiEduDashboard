class AddReferencesToRevision < ActiveRecord::Migration[7.0]
  def change
    add_column :revisions, :references, :integer
  end
end
