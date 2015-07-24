class AddNewArticleCountToCourses < ActiveRecord::Migration
  def change
    add_column :courses, :new_article_count, :integer
  end
end
