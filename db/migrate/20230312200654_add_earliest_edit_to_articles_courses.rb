class AddEarliestEditToArticlesCourses < ActiveRecord::Migration[7.0]
  def change
    add_column :articles_courses, :earliest_edit, :datetime
  end
end
