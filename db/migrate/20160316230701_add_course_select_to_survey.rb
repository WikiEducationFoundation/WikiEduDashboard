class AddCourseSelectToSurvey < ActiveRecord::Migration
  def change
    add_column :surveys, :show_courses, :boolean, :default => false
  end
end
