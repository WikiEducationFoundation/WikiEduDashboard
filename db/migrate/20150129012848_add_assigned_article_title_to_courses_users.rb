class AddAssignedArticleTitleToCoursesUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :courses_users, :assigned_article_title, :string
  end
end
