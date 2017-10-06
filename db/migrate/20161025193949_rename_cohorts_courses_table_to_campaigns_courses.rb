class RenameCohortsCoursesTableToCampaignsCourses < ActiveRecord::Migration[5.0]
  def change
    rename_table :cohorts_courses, :campaigns_courses
  end
end
