class AddNoMeetingDaysToCourses < ActiveRecord::Migration[7.0]
  def change
    add_column :courses, :no_meeting_days, :boolean, default: false
  end
end
