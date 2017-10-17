class AddRoleDescriptionToCoursesUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :courses_users, :role_description, :string
  end
end
