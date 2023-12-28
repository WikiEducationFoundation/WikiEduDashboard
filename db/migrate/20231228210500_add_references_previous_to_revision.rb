class AddReferencesPreviousToRevision < ActiveRecord::Migration[7.0]
  def change
    add_column :revisions, :references_previous, :integer
  end
end
