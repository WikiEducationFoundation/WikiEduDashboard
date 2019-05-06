# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/alerts/articles_for_deletion_monitor"
require_dependency "#{Rails.root}/lib/alerts/dyk_nomination_monitor"
require_dependency "#{Rails.root}/lib/alerts/ga_nomination_monitor"
require_dependency "#{Rails.root}/lib/alerts/course_alert_manager"
require_dependency "#{Rails.root}/lib/alerts/survey_response_alert_manager"
require_dependency "#{Rails.root}/lib/alerts/discretionary_sanctions_monitor"
require_dependency "#{Rails.root}/lib/alerts/high_quality_article_monitor"
require_dependency "#{Rails.root}/lib/alerts/blocked_user_monitor"

module UpdateCycleAlertGenerator
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

    log_message 'Generating course alerts'
    CourseAlertManager.generate_course_alerts

    log_message 'Generating survey response alerts'
    SurveyResponseAlertManager.new.create_alerts

    log_message 'Generate blocked user alerts'
    BlockedUserMonitor.create_alerts_for_recently_blocked_users
  end
end
