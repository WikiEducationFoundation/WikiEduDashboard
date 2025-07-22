class ChangeTypeOfLegacyCourses < ActiveRecord::Migration[4.2]
  def up
    Course.where('id < ?', 10000).update_all(type: 'LegacyCourse')
  end

  def down
    Course.where('id < ?', 10000).update_all(type: 'ClassroomProgramCourse')
  end
end
