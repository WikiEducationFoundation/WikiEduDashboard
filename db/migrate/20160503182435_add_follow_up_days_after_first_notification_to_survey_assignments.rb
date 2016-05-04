class AddFollowUpDaysAfterFirstNotificationToSurveyAssignments < ActiveRecord::Migration
  def change
    add_column :survey_assignments, :follow_up_days_after_first_notification, :integer
    add_column :survey_notifications, :follow_up_sent_at, :datetime
  end
end
