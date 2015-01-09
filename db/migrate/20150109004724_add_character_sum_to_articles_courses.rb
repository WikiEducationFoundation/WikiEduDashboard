class AddCharacterSumToArticlesCourses < ActiveRecord::Migration
  def change
    add_column :articles_courses, :character_sum, :integer
  end
end
