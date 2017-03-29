# frozen_string_literal: true
require "#{Rails.root}/lib/data_cycle/batch_update_logging"
require "#{Rails.root}/lib/course_revision_updater"
require "#{Rails.root}/lib/assignment_updater"
require "#{Rails.root}/lib/importers/revision_score_importer"
require "#{Rails.root}/lib/importers/plagiabot_importer"
require "#{Rails.root}/lib/importers/view_importer"
require "#{Rails.root}/lib/importers/rating_importer"
require "#{Rails.root}/lib/data_cycle/cache_updater"
require "#{Rails.root}/lib/data_cycle/update_cycle_alert_generator"
require "#{Rails.root}/lib/student_greeting_checker"

# Executes all the steps of 'update_constantly' data import task
class ConstantUpdate
  include BatchUpdateLogging
  include CacheUpdater
  include UpdateCycleAlertGenerator

  def initialize
    setup_logger
    set_courses_to_update
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

  def set_courses_to_update
    @courses = Course.ready_for_update.to_a
    log_message "Ready to update #{@courses.count} courses"
  end

  def run_update
    log_start_of_update
    update_revisions_and_articles
    update_new_article_views unless ENV['no_views'] == 'true'
    update_new_article_ratings
    update_all_caches # from CacheUpdater
    remove_needs_update_flags
    update_status_of_ungreeted_students if Features.wiki_ed?
    generate_alerts # from UpdateCycleAlertGenerator
    log_end_of_update 'Constant update finished.'
  end

  ###############
  # Data import #
  ###############

  def update_revisions_and_articles
    log_message 'Importing revisions and articles for all courses'
    CourseRevisionUpdater.import_new_revisions_concurrently(@courses)

    log_message 'Matching assignments to articles and syncing titles'
    AssignmentUpdater.update_assignment_article_ids_and_titles

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

  def update_status_of_ungreeted_students
    log_message 'Updating greeting status of ungreeted students'
    StudentGreetingChecker.check_all_ungreeted_students
  end

  #################################
  # Logging and process managment #
  #################################

  def remove_needs_update_flags
    @courses.select(&:needs_update).each do |course|
      course.update_attribute(:needs_update, false)
    end
  end

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
