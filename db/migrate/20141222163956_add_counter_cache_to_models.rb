class AddCounterCacheToModels < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :course_count, :integer
    add_column :users, :article_count, :integer
    add_column :users, :revision_count, :integer

    add_column :courses, :user_count, :integer
    add_column :courses, :article_count, :integer
    add_column :courses, :revision_count, :integer

    add_column :articles, :revision_count, :integer
  end
end
