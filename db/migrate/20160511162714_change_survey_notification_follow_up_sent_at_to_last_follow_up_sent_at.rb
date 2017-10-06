class ChangeSurveyNotificationFollowUpSentAtToLastFollowUpSentAt < ActiveRecord::Migration[4.2]
  def change
    rename_column :survey_notifications, :follow_up_sent_at, :last_follow_up_sent_at
  end
end
