# frozen_string_literal: true

require_dependency "#{Rails.root}/app/workers/daily_update/update_users_worker"
require_dependency "#{Rails.root}/app/workers/daily_update/update_commons_uploads_worker"
require_dependency "#{Rails.root}/app/workers/daily_update/find_assignments_worker"
require_dependency "#{Rails.root}/app/workers/daily_update/clean_articles_courses_worker"
require_dependency "#{Rails.root}/app/workers/daily_update/import_ratings_worker"
require_dependency "#{Rails.root}/app/workers/daily_update/update_article_status_worker"
require_dependency "#{Rails.root}/app/workers/daily_update/overdue_training_alert_worker"
require_dependency "#{Rails.root}/app/workers/daily_update/salesforce_sync_worker"

require_dependency "#{Rails.root}/lib/data_cycle/batch_update_logging"

# Executes all the steps of 'update_constantly' data import task
class DailyUpdate
  include BatchUpdateLogging

  QUEUE = 'daily_update'

  def initialize
    setup_logger
    return if updates_paused?
    return if update_running?(:daily)

    run_update_with_pid_files(:daily)
  end

  private

  def run_update
    log_start_of_update 'Daily update tasks are beginning.'
    update_users
    update_commons_uploads
    update_article_data
    generate_overdue_training_alerts if Features.wiki_ed?
    push_course_data_to_salesforce if Features.wiki_ed?
    log_end_of_update 'Daily update finished.'
  # rubocop:disable Lint/RescueException
  rescue Exception => e
    log_end_of_update 'Daily update failed.'
    raise e
  end
  # rubocop:enable Lint/RescueException

  ###############
  # Data import #
  ###############

  def update_users
    log_message 'Updating registration dates for new Users'
    UpdateUsersWorker.set(queue: QUEUE).perform_async
  end

  def update_commons_uploads
    log_message 'Identifying deleted Commons uploads'
    UpdateCommonsUploadsWorker.set(queue: QUEUE).perform_async
  end

  def update_article_data
    log_message 'Finding articles that match assignment titles'
    FindAssignmentsWorker.set(queue: QUEUE).perform_async

    log_message 'Rebuilding ArticlesCourses for all current students'
    CleanArticlesCoursesWorker.set(queue: QUEUE).perform_async

    log_message 'Updating ratings for all articles'
    ImportRatingsWorker.set(queue: QUEUE).perform_async

    log_message 'Updating article namespace and deleted status'
    UpdateArticleStatusWorker.set(queue: QUEUE).perform_async
  end

  ##########
  # Alerts #
  ##########
  def generate_overdue_training_alerts
    log_message 'Generating alerts for overdue trainings'
    OverdueTrainingAlertWorker.set(queue: QUEUE).perform_async
  end

  ###############
  # Data export #
  ###############
  def push_course_data_to_salesforce
    log_message 'Pushing course data to Salesforce'
    SalesforceSyncWorker.set(queue: QUEUE).perform_async
  end
end
