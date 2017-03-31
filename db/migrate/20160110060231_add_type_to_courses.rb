class AddTypeToCourses < ActiveRecord::Migration[4.2]
  def change
    add_column :courses, :type, :string, default: 'ClassroomProgramCourse'
  end
end
