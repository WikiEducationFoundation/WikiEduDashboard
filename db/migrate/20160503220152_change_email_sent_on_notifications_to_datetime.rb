class ChangeEmailSentOnNotificationsToDatetime < ActiveRecord::Migration[4.2]
  def change
    add_column :survey_notifications, :email_sent_at, :datetime, after: :email_sent
    SurveyNotification.where(email_sent: true).update_all('email_sent_at=updated_at')
    remove_column :survey_notifications, :email_sent
  end
end
