class AddWp10AndWp10PrevToRevision < ActiveRecord::Migration
  def change
    add_column :revisions, :wp10, :string
    add_column :revisions, :wp10_previous, :string
  end
end
