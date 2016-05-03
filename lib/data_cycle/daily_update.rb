require "#{Rails.root}/lib/importers/assigned_article_importer"
require "#{Rails.root}/lib/cleaners"
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
    wait_until_constant_update_finishes

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
    update_article_data
    update_article_views unless ENV['no_views'] == 'true'
    update_commons_uploads
    CacheUpdater.update_all_caches
    log_end_of_update
  end

  ###############
  # Data import #
  ###############

  def update_article_data
    Rails.logger.debug 'Finding articles that match assignment titles'
    AssignedArticleImporter.import_articles_for_assignments

    Rails.logger.debug 'Rebuilding ArticlesCourses for all current students'
    Cleaners.rebuild_articles_courses

    Rails.logger.debug 'Updating ratings for all articles'
    RatingImporter.update_all_ratings

    Rails.logger.debug 'Updating article namespace and deleted status'
    ArticleStatusManager.update_article_status
  end

  def update_article_views
    Rails.logger.debug 'Updating article views'
    ViewImporter.update_all_views
  end

  def update_commons_uploads
    Rails.logger.debug 'Identifying deleted Commons uploads'
    UploadImporter.find_deleted_files(CommonsUpload.where(deleted: false))

    Rails.logger.debug 'Updating Commons uploads'
    UploadImporter.import_all_uploads(User.all)

    Rails.logger.debug 'Updating Commons uploads usage counts'
    UploadImporter.update_usage_count(CommonsUpload.where(deleted: false))

    Rails.logger.debug 'Getting thumbnail urls for Commons uploads'
    thumbless_uploads = CommonsUpload.where(thumburl: nil, deleted: false)
    UploadImporter.import_urls_in_batches(thumbless_uploads)
  end

  #################################
  # Logging and process managment #
  #################################

  def wait_until_constant_update_finishes
    return unless constant_update_running?

    begin
      File.open(SLEEP_FILE, 'w') { |f| f.puts Process.pid }
      while constant_update_running?
        Rails.logger.debug 'Delaying update_daily task for 5 minutes...'
        sleep(5.minutes)
      end
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

  def log_end_of_update
    @end_time = Time.zone.now
    total_time = distance_of_time_in_words(@start_time, @end_time)
    Rails.logger.info "Daily update finished in #{total_time}."
    Raven.capture_message 'Daily update finished.',
                          level: 'info',
                          tags: { update_time: total_time },
                          extra: { exact_update_time: (@end_time - @start_time) }
  end
end
