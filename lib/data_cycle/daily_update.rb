# frozen_string_literal: true
require "#{Rails.root}/lib/data_cycle/batch_update_logging"
require "#{Rails.root}/lib/importers/assigned_article_importer"
require "#{Rails.root}/lib/articles_courses_cleaner"
require "#{Rails.root}/lib/importers/rating_importer"
require "#{Rails.root}/lib/article_status_manager"
require "#{Rails.root}/lib/importers/view_importer"
require "#{Rails.root}/lib/importers/upload_importer"
require "#{Rails.root}/lib/data_cycle/cache_updater"

# Executes all the steps of 'update_constantly' data import task
class DailyUpdate
  include BatchUpdateLogging

  def initialize
    setup_logger
    return if updates_paused?
    return if daily_update_running?
    wait_until_constant_update_finishes if constant_update_running?

    begin
      create_pid_file
      run_update
    ensure
      delete_pid_file
    end
  end

  private

  def run_update
    log_start_of_update
    update_commons_uploads
    update_article_data
    update_article_views unless ENV['no_views'] == 'true'
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

  def update_commons_uploads
    log_message 'Identifying deleted Commons uploads'
    UploadImporter.find_deleted_files(CommonsUpload.where(deleted: false))

    log_message 'Updating Commons uploads for current students'
    UploadImporter.import_all_uploads(User.current.role('student'))

    log_message 'Updating Commons uploads usage counts'
    UploadImporter.update_usage_count_by_course(Course.all)

    log_message 'Getting thumbnail urls for Commons uploads'
    thumbless_uploads = CommonsUpload.where(thumburl: nil, deleted: false)
    UploadImporter.import_urls_in_batches(thumbless_uploads)
  end

  def update_article_data
    log_message 'Finding articles that match assignment titles'
    AssignedArticleImporter.import_articles_for_assignments

    log_message 'Rebuilding ArticlesCourses for all current students'
    ArticlesCoursesCleaner.rebuild_articles_courses

    log_message 'Updating ratings for all articles'
    RatingImporter.update_all_ratings

    log_message 'Updating article namespace and deleted status'
    ArticleStatusManager.update_article_status
  end

  def update_article_views
    log_message 'Updating article views'
    ViewImporter.update_all_views(true)
  end

  #################################
  # Logging and process managment #
  #################################

  def wait_until_constant_update_finishes
    sleep_time = 0
    log_message 'Delaying daily until current update finishes...'
    begin
      File.open(SLEEP_FILE, 'w') { |f| f.puts Process.pid }
      while constant_update_running?
        sleep_time += 5
        sleep(5.minutes)
      end
      log_message "Starting daily update after waiting #{sleep_time} minutes"
    ensure
      File.delete SLEEP_FILE if File.exist? SLEEP_FILE
    end
  end

  def create_pid_file
    File.open(DAILY_UPDATE_PID_FILE, 'w') { |f| f.puts Process.pid }
  end

  def delete_pid_file
    File.delete DAILY_UPDATE_PID_FILE if File.exist? DAILY_UPDATE_PID_FILE
  end

  def log_start_of_update
    @start_time = Time.zone.now
    Rails.logger.info 'Daily update tasks are beginning.'
  end
end
