class AddViewsToRevisions < ActiveRecord::Migration
  def change
    add_column :revisions, :views, :int
  end
end
