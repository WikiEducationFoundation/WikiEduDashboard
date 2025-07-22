class AddMwPageIdIndexToArticles < ActiveRecord::Migration[5.0]
  def change
    add_index :articles, :mw_page_id
  end
end
