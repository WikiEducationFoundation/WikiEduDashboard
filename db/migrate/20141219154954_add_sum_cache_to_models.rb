class AddSumCacheToModels < ActiveRecord::Migration[4.2]
  def change
    add_column :articles, :character_sum, :integer
    add_column :courses, :character_sum, :integer
    add_column :courses, :view_sum, :integer
    add_column :users, :character_sum, :integer
    add_column :users, :view_sum, :integer
  end
end
