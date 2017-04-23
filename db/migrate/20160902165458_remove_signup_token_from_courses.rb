class RemoveSignupTokenFromCourses < ActiveRecord::Migration[4.2]
  def change
    remove_column :courses, :signup_token
  end
end
