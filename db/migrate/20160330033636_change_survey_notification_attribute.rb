class ChangeSurveyNotificationAttribute < ActiveRecord::Migration
  def change
    rename_column :survey_notifications, :notification_sent, :notification_dismissed
  end
end
