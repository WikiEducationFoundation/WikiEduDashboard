class RemoveCachedDataFromUser < ActiveRecord::Migration[4.2]
  def up
    remove_column :users, :character_sum
    remove_column :users, :view_sum
    remove_column :users, :course_count
    remove_column :users, :article_count
    remove_column :users, :revision_count
  end

  def down
    add_column :users, :character_sum, :integer, default: 0
    add_column :users, :view_sum, :integer, default: 0
    add_column :users, :course_count, :integer, default: 0
    add_column :users, :article_count, :integer, default: 0
    add_column :users, :revision_count, :integer, default: 0
  end
end
