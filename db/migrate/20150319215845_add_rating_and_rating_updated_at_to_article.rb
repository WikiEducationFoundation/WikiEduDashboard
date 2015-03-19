class AddRatingAndRatingUpdatedAtToArticle < ActiveRecord::Migration
  def change
    add_column :articles, :rating, :string
    add_column :articles, :rating_updated_at, :datetime
  end
end
