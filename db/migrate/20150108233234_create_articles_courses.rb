class CreateArticlesCourses < ActiveRecord::Migration[4.2]
  def change
    create_table :articles_courses do |t|

      t.timestamps
    end
  end
end
