class AddDefaultCourseTypeToCampaigns < ActiveRecord::Migration[5.1]
  def change
    add_column :campaigns, :default_course_type, :string
  end
end
