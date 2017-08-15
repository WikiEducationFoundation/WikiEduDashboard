# frozen_string_literal: true

require "#{Rails.root}/lib/articles_for_deletion_monitor"
require "#{Rails.root}/lib/dyk_nomination_monitor"
require "#{Rails.root}/lib/course_alert_manager"
require "#{Rails.root}/lib/alerts/survey_response_alert_manager"

module UpdateCycleAlertGenerator
  def generate_alerts
    log_message 'Generating AfD alerts'
    ArticlesForDeletionMonitor.create_alerts_for_course_articles

    log_message 'Generating DYK alerts'
    DYKNominationMonitor.create_alerts_for_course_articles

    log_message 'Generating course alerts'
    CourseAlertManager.generate_course_alerts

    log_message 'Generating survey response alerts'
    SurveyResponseAlertManager.new.create_alerts
  end
end
