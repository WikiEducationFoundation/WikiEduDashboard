class AddAssignedArticleTitleToCoursesUsers < ActiveRecord::Migration
  def change
    add_column :courses_users, :assigned_article_title, :string
  end
end
