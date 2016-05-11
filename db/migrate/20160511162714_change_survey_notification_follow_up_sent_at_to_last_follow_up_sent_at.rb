class ChangeSurveyNotificationFollowUpSentAtToLastFollowUpSentAt < ActiveRecord::Migration
  def change
    rename_column :survey_notifications, :follow_up_sent_at, :last_follow_up_sent_at
  end
end
