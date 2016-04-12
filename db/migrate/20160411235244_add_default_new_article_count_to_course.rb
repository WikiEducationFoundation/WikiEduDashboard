class AddDefaultNewArticleCountToCourse < ActiveRecord::Migration
  def change
    change_column_default :courses, :new_article_count, 0
  end
end
