class AddTypeToCourses < ActiveRecord::Migration
  def change
    add_column :courses, :type, :string, default: 'ClassroomProgramCourse'
  end
end
