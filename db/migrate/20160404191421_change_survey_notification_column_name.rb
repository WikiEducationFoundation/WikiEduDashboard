class ChangeSurveyNotificationColumnName < ActiveRecord::Migration[4.2]
  def change
    rename_column :survey_notifications, :notification_dismissed, :dismissed
  end
end
