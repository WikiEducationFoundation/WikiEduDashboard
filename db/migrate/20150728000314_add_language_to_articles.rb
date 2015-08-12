class AddLanguageToArticles < ActiveRecord::Migration
  def change
    add_column :articles, :language, :string, limit: 10
  end
end
