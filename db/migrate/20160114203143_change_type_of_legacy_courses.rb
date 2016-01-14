class ChangeTypeOfLegacyCourses < ActiveRecord::Migration
  def up
    Course.where('id < ?', 10000).update_all(type: 'LegacyCourse')
  end

  def down
    Course.where('id < ?', 10000).update_all(type: 'ClassroomProgramCourse')
  end
end
