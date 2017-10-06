class AddRealNameToCoursesUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :courses_users, :real_name, :string
  end
end
