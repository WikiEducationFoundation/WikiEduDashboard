class RemoveShowCoursesFromSurvey < ActiveRecord::Migration
  def change
    remove_column :surveys, :show_courses
  end
end
