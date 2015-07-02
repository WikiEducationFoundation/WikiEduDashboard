class AddSystemToRevisions < ActiveRecord::Migration
  def change
    add_column :revisions, :system, :boolean, :default => false
  end
end
