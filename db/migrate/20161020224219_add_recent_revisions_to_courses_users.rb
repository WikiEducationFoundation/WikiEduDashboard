class AddRecentRevisionsToCoursesUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :courses_users, :recent_revisions, :integer, default: 0
  end
end
