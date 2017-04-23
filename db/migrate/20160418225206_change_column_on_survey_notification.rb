class ChangeColumnOnSurveyNotification < ActiveRecord::Migration[4.2]
  def change
    rename_column :survey_notifications, :courses_user_id, :courses_users_id
  end
end
