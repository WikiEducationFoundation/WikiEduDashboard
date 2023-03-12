class AddViewsUpdatedAtToArticlesCourses < ActiveRecord::Migration[7.0]
  def change
    add_column :articles_courses, :views_updated_at, :datetime
  end
end
