class AddNewArticleCountToCourses < ActiveRecord::Migration[4.2]
  def change
    add_column :courses, :new_article_count, :integer
  end
end
