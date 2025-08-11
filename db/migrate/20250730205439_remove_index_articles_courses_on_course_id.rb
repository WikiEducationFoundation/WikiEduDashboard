class RemoveIndexArticlesCoursesOnCourseId < ActiveRecord::Migration[7.0]
  def change
    remove_index :articles_courses, name: :index_articles_courses_on_course_id
  end
end
