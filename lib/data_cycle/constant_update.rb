# frozen_string_literal: true

# Adding these model dependencies explicitly is intended to avoid intermittent
# NameError and ciruclar dependency errors
require_dependency Rails.root.join('app/models/wiki_content/article')
require_dependency Rails.root.join('app/models/wiki_content/revision')
require_dependency Rails.root.join('app/models/course')
require_dependency Rails.root.join('app/models/course_data/week')
require_dependency Rails.root.join('app/models/course_data/block')

require_dependency Rails.root.join('lib/data_cycle/batch_update_logging')
require_dependency Rails.root.join('lib/assignment_updater')
require_dependency Rails.root.join('lib/importers/plagiabot_importer')
require_dependency Rails.root.join('app/services/check_assignment_status')
require_dependency Rails.root.join('lib/importers/rating_importer')
require_dependency Rails.root.join('lib/data_cycle/update_cycle_alert_generator')
require_dependency Rails.root.join('lib/student_greeting_checker')

# Executes all the steps of 'update_constantly' data import task
class ConstantUpdate
  include BatchUpdateLogging
  include UpdateCycleAlertGenerator

  def initialize
    setup_logger
    return if updates_paused?
    run_update
  end

  private

  def run_update
    log_start_of_update 'Constant update tasks are beginning.'
    update_revisions_and_articles
    update_new_article_ratings
    check_assignment_sandboxes if Features.wiki_ed?
    update_status_of_ungreeted_students if Features.wiki_ed?
    generate_alerts # from UpdateCycleAlertGenerator
    sparse_log_end_of_update 'Constant update finished.', UpdateLogger.number_of_constant_updates
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

    log_message 'Checking for plagiarism in recent revisions'
    PlagiabotImporter.find_recent_plagiarism
  end

  def check_assignment_sandboxes
    log_message 'Updating assignment sandbox statuses'
    CheckAssignmentStatus.check_current_assignments
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
