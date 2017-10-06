class ChangeSurveyNotificationAttribute < ActiveRecord::Migration[4.2]
  def change
    rename_column :survey_notifications, :notification_sent, :notification_dismissed
  end
end
