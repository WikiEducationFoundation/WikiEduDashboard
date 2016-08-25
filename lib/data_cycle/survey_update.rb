# frozen_string_literal: true
require "#{Rails.root}/lib/data_cycle/batch_update_logging"
require "#{Rails.root}/lib/surveys/survey_notifications_manager"

class SurveyUpdate
  include BatchUpdateLogging

  def initialize
    setup_logger
    log_start_of_update
    create_survey_notifications
    send_survey_notifications
    send_survey_notification_follow_ups
    log_end_of_update 'Survey update finished.'
  end

  private

  def create_survey_notifications
    log_message 'Creating new SurveyNotifications'
    before_count = SurveyNotification.count
    SurveyNotificationsManager.create_notifications
    after_count = SurveyNotification.count
    log_message "#{after_count - before_count} SurveyNotifications created"
  end

  def send_survey_notifications
    log_message 'Sending survey invitation emails'
    before_count = SurveyNotification.where.not(email_sent_at: nil).count
    SurveyNotification.active.each do |notification|
      notification.send_email
      sleep 2 # Don't send emails too quickly, to avoid being throttled by gmail
    end
    after_count = SurveyNotification.where.not(email_sent_at: nil).count
    log_message "#{after_count - before_count} survey invitations sent"
  end

  def send_survey_notification_follow_ups
    log_message 'Sending survey reminder emails'
    before_count = SurveyNotification.sum(:follow_up_count)
    SurveyNotification.active.each do |notification|
      notification.send_follow_up
      sleep 2 # Don't send emails too quickly, to avoid being throttled by gmail
    end
    after_count = SurveyNotification.sum(:follow_up_count)
    log_message "#{after_count - before_count} survey reminders sent"
  end

  def log_start_of_update
    @start_time = Time.zone.now
  end
end
