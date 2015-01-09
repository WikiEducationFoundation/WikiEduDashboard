class CreateArticlesCourses < ActiveRecord::Migration
  def change
    create_table :articles_courses do |t|

      t.timestamps
    end
  end
end
