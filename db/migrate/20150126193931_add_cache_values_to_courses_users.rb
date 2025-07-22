class AddCacheValuesToCoursesUsers < ActiveRecord::Migration[4.2]
  def change
    rename_column :courses_users, :character_sum, :characters_sum_ms
    add_column :courses_users, :characters_sum_us, :integer, :default => 0
    add_column :courses_users, :revision_count, :integer, :default => 0
  end
end
