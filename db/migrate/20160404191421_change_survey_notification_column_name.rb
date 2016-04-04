class ChangeSurveyNotificationColumnName < ActiveRecord::Migration
  def change
    rename_column :survey_notifications, :notification_dismissed, :dismissed
  end
end
