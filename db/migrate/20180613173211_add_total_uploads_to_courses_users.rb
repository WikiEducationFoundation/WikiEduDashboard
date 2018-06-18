class AddTotalUploadsToCoursesUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :courses_users, :total_uploads, :integer
  end
end
