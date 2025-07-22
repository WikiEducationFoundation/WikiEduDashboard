class AddFirstRevisionToArticlesCourses < ActiveRecord::Migration[7.0]
  def change
    add_column :articles_courses, :first_revision, :datetime
  end
end
