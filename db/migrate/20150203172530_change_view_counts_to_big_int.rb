class ChangeViewCountsToBigInt < ActiveRecord::Migration[4.2]
  def change
    change_column :articles, :views, :integer, :limit => 5
    change_column :articles_courses, :view_count, :integer, :limit => 5
    change_column :courses, :view_sum, :integer, :limit => 5
    change_column :revisions, :views, :integer, :limit => 5
    change_column :users, :view_sum, :integer, :limit => 5
  end
end
