class RemoveIndexCoursesWikisOnCourseId < ActiveRecord::Migration[7.0]
  def change
    remove_index :courses_wikis, name: "index_courses_wikis_on_course_id"
  end
end
