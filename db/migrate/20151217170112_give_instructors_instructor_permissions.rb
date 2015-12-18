class GiveInstructorsInstructorPermissions < ActiveRecord::Migration
  def change
    User.joins(:courses_users).where(courses_users: { role: 1 }).update_all(permissions: 2)
  end
end
