class AddReferencesToRevisions < ActiveRecord::Migration[5.2]
  def change
    add_column :revisions, :references, :integer, default: 0
  end
end
