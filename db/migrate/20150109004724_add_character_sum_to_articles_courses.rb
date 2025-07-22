class AddCharacterSumToArticlesCourses < ActiveRecord::Migration[4.2]
  def change
    add_column :articles_courses, :character_sum, :integer
  end
end
