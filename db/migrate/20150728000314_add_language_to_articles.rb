class AddLanguageToArticles < ActiveRecord::Migration[4.2]
  def change
    add_column :articles, :language, :string, limit: 10
  end
end
