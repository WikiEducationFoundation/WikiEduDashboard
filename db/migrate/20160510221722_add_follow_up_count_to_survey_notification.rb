class AddFollowUpCountToSurveyNotification < ActiveRecord::Migration[4.2]
  def change
    add_column :survey_notifications, :follow_up_count, :integer, default: 0
  end
end
