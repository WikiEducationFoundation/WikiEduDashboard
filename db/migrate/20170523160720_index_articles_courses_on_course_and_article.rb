class IndexArticlesCoursesOnCourseAndArticle < ActiveRecord::Migration[5.0]
  def change
    add_index :articles_courses, :course_id
    add_index :articles_courses, :article_id
  end
end
