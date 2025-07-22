class AddDefaultNewArticleCountToCourse < ActiveRecord::Migration[4.2]
  def change
    change_column_default :courses, :new_article_count, 0
  end
end
