class CreateSurveyNotification < ActiveRecord::Migration[4.2]
  def change
    create_table :survey_notifications do |t|
      t.belongs_to :courses_user, index: true
      t.belongs_to :course, index: true
      t.belongs_to :survey_assignment, index: true
      t.boolean :notification_sent, default: false
      t.boolean :email_sent, default: false
      t.timestamps null: false
    end
  end
end
