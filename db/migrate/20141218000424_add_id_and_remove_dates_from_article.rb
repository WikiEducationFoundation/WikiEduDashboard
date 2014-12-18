class RemoveDatesFromArticle < ActiveRecord::Migration
  def change
    remove_column :articles, :created_at
    remove_column :articles, :updated_at
  end
end
