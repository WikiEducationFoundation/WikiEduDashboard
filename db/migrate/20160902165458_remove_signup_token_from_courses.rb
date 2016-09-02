class RemoveSignupTokenFromCourses < ActiveRecord::Migration
  def change
    remove_column :courses, :signup_token
  end
end
