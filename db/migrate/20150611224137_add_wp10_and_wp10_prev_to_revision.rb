class AddWp10AndWp10PrevToRevision < ActiveRecord::Migration[4.2]
  def change
    add_column :revisions, :wp10, :string
    add_column :revisions, :wp10_previous, :string
  end
end
