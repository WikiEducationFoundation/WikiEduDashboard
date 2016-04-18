class ChangeColumnOnSurveyNotification < ActiveRecord::Migration
  def change
    rename_column :survey_notifications, :courses_user_id, :courses_users_id
  end
end
