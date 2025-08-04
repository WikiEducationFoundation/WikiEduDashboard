class RemoveIndexCategoriesCoursesOnCourseId < ActiveRecord::Migration[7.0]
  def change
    remove_index :categories_courses, name: "index_categories_courses_on_course_id"
  end
end
