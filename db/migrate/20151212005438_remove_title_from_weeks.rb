class RemoveTitleFromWeeks < ActiveRecord::Migration
  def up
    remove_column :weeks, :title
  end

  def down
    add_column :weeks, :title, :string
  end
end
