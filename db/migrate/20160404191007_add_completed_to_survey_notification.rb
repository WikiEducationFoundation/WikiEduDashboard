class AddCompletedToSurveyNotification < ActiveRecord::Migration[4.2]
  def change
    add_column :survey_notifications, :completed, :boolean, default: false
  end
end
