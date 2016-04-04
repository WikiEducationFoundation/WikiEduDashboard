class AddCompletedToSurveyNotification < ActiveRecord::Migration
  def change
    add_column :survey_notifications, :completed, :boolean, default: false
  end
end
