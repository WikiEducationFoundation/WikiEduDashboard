class AddSystemToRevisions < ActiveRecord::Migration[4.2]
  def change
    add_column :revisions, :system, :boolean, :default => false
  end
end
