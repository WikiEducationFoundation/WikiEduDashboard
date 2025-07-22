class AddViewsToRevisions < ActiveRecord::Migration[4.2]
  def change
    add_column :revisions, :views, :int
  end
end
