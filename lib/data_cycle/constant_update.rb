require "#{Rails.root}/lib/data_cycle/batch_update_logging"
require "#{Rails.root}/lib/legacy_courses/legacy_course_importer"
require "#{Rails.root}/lib/importers/user_importer"
require "#{Rails.root}/lib/importers/revision_importer"
require "#{Rails.root}/lib/importers/revision_score_importer"
require "#{Rails.root}/lib/importers/plagiabot_importer"
require "#{Rails.root}/lib/importers/view_importer"
require "#{Rails.root}/lib/importers/rating_importer"
require "#{Rails.root}/lib/articles_for_deletion_monitor"
require "#{Rails.root}/lib/course_alert_manager"
require "#{Rails.root}/lib/data_cycle/cache_updater"
require "#{Rails.root}/lib/student_greeter"

# Executes all the steps of 'update_constantly' data import task
class ConstantUpdate
  include BatchUpdateLogging

  def initialize
    setup_logger
    return if updates_paused?
    return unless no_other_updates_running?

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
    update_legacy_courses if Features.enable_legacy_courses?
    update_users
    update_revisions_and_articles
    update_new_article_views unless ENV['no_views'] == 'true'
    update_new_article_ratings
    CacheUpdater.update_all_caches
    greet_ungreeted_students
    generate_alerts
    log_end_of_update 'Constant update finished.'
  end

  ###############
  # Data import #
  ###############
  def update_legacy_courses
    log_message 'Updating data for legacy course'
    LegacyCourseImporter.update_all_courses
  end

  def update_users
    log_message 'Updating global ids and training status'
    UserImporter.update_users
  end

  def update_revisions_and_articles
    log_message 'Updating all revisions'
    RevisionImporter.update_all_revisions

    log_message 'Importing wp10 scores for all en.wiki revisions'
    RevisionScoreImporter.new.update_revision_scores

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

  ###############
  # Batch edits #
  ###############

  def greet_ungreeted_students
    log_message 'Greeting students in classes with greeters'
    StudentGreeter.greet_all_ungreeted_students
  end

  ##########
  # Alerts #
  ##########

  def generate_alerts
    log_message 'Generating AfD alerts'
    ArticlesForDeletionMonitor.create_alerts_for_course_articles

    course_alert_manager = CourseAlertManager.new

    log_message 'Generating no-enrolled-students alerts'
    course_alert_manager.create_no_students_alerts
    log_message 'Generating untrained-students alerts'
    course_alert_manager.create_untrained_students_alerts
    log_message 'Generating productive course alerts'
    course_alert_manager.create_productive_course_alerts
    log_message 'Generating continued course activity alerts'
    course_alert_manager.create_continued_course_activity_alerts
  end

  #################################
  # Logging and process managment #
  #################################

  def no_other_updates_running?
    return false if daily_update_running?
    return false if constant_update_running?
    return false if update_waiting_to_run?
    true
  end

  def create_pid_file
    File.open(CONSTANT_UPDATE_PID_FILE, 'w') { |f| f.puts Process.pid }
  end

  def delete_pid_file
    File.delete CONSTANT_UPDATE_PID_FILE if File.exist? CONSTANT_UPDATE_PID_FILE
  end

  def log_start_of_update
    @start_time = Time.zone.now
    Rails.logger.info 'Constant update tasks are beginning.'
  end
end
