class RemoveShowCoursesFromSurvey < ActiveRecord::Migration[4.2]
  def change
    remove_column :surveys, :show_courses
  end
end
