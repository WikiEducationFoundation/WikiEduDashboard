class AddReferencesSumToCoursesUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :courses_users, :refs_sum_ms, :integer, :default => 0
  end
end
