class AddCourseSelectToSurvey < ActiveRecord::Migration[4.2]
  def change
    add_column :surveys, :show_courses, :boolean, :default => false
  end
end
