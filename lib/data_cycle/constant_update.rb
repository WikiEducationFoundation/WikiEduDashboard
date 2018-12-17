# frozen_string_literal: true

# Adding these model dependencies explicitly is intended to avoid intermittent
# NameError and ciruclar dependency errors
require_dependency "#{Rails.root}/app/models/wiki_content/article"
require_dependency "#{Rails.root}/app/models/wiki_content/revision"
require_dependency "#{Rails.root}/app/models/course"
require_dependency "#{Rails.root}/app/models/course_data/week"
require_dependency "#{Rails.root}/app/models/course_data/block"

require_dependency "#{Rails.root}/lib/data_cycle/batch_update_logging"
require_dependency "#{Rails.root}/lib/assignment_updater"
require_dependency "#{Rails.root}/lib/importers/revision_score_importer"
require_dependency "#{Rails.root}/lib/importers/plagiabot_importer"
require_dependency "#{Rails.root}/lib/importers/view_importer"
require_dependency "#{Rails.root}/lib/importers/rating_importer"
require_dependency "#{Rails.root}/lib/data_cycle/update_cycle_alert_generator"
require_dependency "#{Rails.root}/lib/student_greeting_checker"

# Executes all the steps of 'update_constantly' data import task
class ConstantUpdate
  include BatchUpdateLogging
  include UpdateCycleAlertGenerator

  def initialize
    setup_logger
    return if updates_paused?
    return if update_running?(:constant)

    run_update_with_pid_files(:constant)
  end

  private

  def run_update
    log_start_of_update 'Constant update tasks are beginning.'
    update_revisions_and_articles
    update_new_article_views unless ENV['no_views'] == 'true'
    update_new_article_ratings
    update_status_of_ungreeted_students if Features.wiki_ed?
    generate_alerts # from UpdateCycleAlertGenerator
    log_end_of_update 'Constant update finished.'
  # rubocop:disable Lint/RescueException
  rescue Exception => e
    log_end_of_update 'Constant update failed.'
    raise e
  end
  # rubocop:enable Lint/RescueException

  ###############
  # Data import #
  ###############

  def update_revisions_and_articles
    log_message 'Matching assignments to articles and syncing titles'
    AssignmentUpdater.update_assignment_article_ids_and_titles

    log_message 'Importing articlequality scores for all revisions on supported wikis'
    RevisionScoreImporter.update_revision_scores_for_all_wikis

    log_message 'Checking for plagiarism in recent revisions'
    PlagiabotImporter.find_recent_plagiarism
  end

  def update_new_article_views
    log_message 'Updating views for newly added articles'
    ViewImporter.update_new_views
  end

  def update_new_article_ratings
    log_message 'Updating ratings for new articles'
    RatingImporter.update_new_ratings
  end

  def update_status_of_ungreeted_students
    log_message 'Updating greeting status of ungreeted students'
    StudentGreetingChecker.check_all_ungreeted_students
  end
end
