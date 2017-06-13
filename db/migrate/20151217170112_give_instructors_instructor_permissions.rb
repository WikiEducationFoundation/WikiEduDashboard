class GiveInstructorsInstructorPermissions < ActiveRecord::Migration[4.2]
  def change
    User.joins(:courses_users).where(courses_users: { role: 1 }).update_all(permissions: 2)
  end
end
