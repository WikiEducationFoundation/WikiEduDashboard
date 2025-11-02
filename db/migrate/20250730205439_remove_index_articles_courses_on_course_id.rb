class RemoveIndexArticlesCoursesOnCourseId < ActiveRecord::Migration[7.0]
  def change
    if index_exists?(:articles_courses, name: :index_articles_courses_on_course_id)
      remove_index :articles_courses, name: :index_articles_courses_on_course_id
    end
  end
end
