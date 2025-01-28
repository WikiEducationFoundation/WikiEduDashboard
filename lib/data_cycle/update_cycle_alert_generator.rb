# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/alerts/articles_for_deletion_monitor"
require_dependency "#{Rails.root}/lib/alerts/d_y_k_nomination_monitor"
require_dependency "#{Rails.root}/lib/alerts/g_a_nomination_monitor"
require_dependency "#{Rails.root}/lib/alerts/course_alert_manager"
require_dependency "#{Rails.root}/lib/alerts/survey_response_alert_manager"
require_dependency "#{Rails.root}/lib/alerts/discretionary_sanctions_monitor"
require_dependency "#{Rails.root}/lib/alerts/high_quality_article_monitor"
require_dependency "#{Rails.root}/lib/alerts/protected_article_monitor"
require_dependency "#{Rails.root}/lib/alerts/blocked_user_monitor"
require "#{Rails.root}/lib/alerts/de_userfying_edit_alert_monitor"
require "#{Rails.root}/lib/alerts/medicine_article_monitor"

module UpdateCycleAlertGenerator
  # rubocop:disable Metrics/MethodLength
  def generate_alerts
    log_message 'Generating AfD alerts'
    ArticlesForDeletionMonitor.create_alerts_for_course_articles

    log_message 'Generating discretionary sanctions alerts'
    DiscretionarySanctionsMonitor.create_alerts_for_course_articles

    log_message 'Generating DYK alerts'
    DYKNominationMonitor.create_alerts_for_course_articles

    log_message 'Generating Good Article nominationalerts'
    GANominationMonitor.create_alerts_for_course_articles

    log_message 'Generating GA and FA edit alerts'
    HighQualityArticleMonitor.create_alerts_for_course_articles

    log_message 'Generating protected article alerts'
    ProtectedArticleMonitor.create_alerts_for_assigned_articles

    log_message 'Generating course alerts'
    CourseAlertManager.generate_course_alerts

    log_message 'Generating survey response alerts'
    SurveyResponseAlertManager.new.create_alerts

    log_message 'Generate blocked user alerts'
    BlockedUserMonitor.create_alerts_for_recently_blocked_users

    log_message 'Generate de-userfying edits alerts'
    DeUserfyingEditAlertMonitor.create_alerts_for_deuserfying_edits

    generate_alert_for_med_articles
  end

  def generate_alert_for_med_articles
    return unless Features.wiki_ed?
    log_message 'Generate WP Medicine article assignment without medical \
      content training module alert'
    MedicineArticleMonitor.create_alerts_for_no_med_training_for_course
  end

  # rubocop:enable Metrics/MethodLength
end
