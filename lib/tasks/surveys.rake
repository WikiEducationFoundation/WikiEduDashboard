require "#{Rails.root}/lib/surveys/survey_notifications_manager"

namespace :surveys do
  desc 'Find CoursesUsers ready to receive surveys and create a SurveyNotification for each'
  task create_notifications: :environment do
    SurveyNotificationsManager.create_notifications
  end

  desc 'Find SurveyNotifications that haven\'t been sent and send them'
  task send_notifications: :environment do
    SurveyNotification.active.each(&:send_email)
  end

  desc 'Send follow-up survey notifications if configured on the parent notification'
  task send_notification_follow_ups: :environment do
    SurveyNotification.active.each(&:send_follow_up)
  end
end
