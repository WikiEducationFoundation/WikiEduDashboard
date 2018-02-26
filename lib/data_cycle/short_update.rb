# frozen_string_literal: true

require "#{Rails.root}/lib/data_cycle/batch_update_logging"
require "#{Rails.root}/lib/course_revision_updater"
require "#{Rails.root}/lib/assignment_updater"
require "#{Rails.root}/lib/importers/revision_score_importer"
require "#{Rails.root}/lib/importers/plagiabot_importer"
require "#{Rails.root}/lib/importers/upload_importer"
require "#{Rails.root}/lib/importers/view_importer"
require "#{Rails.root}/lib/importers/rating_importer"
require "#{Rails.root}/lib/data_cycle/cache_updater"
require "#{Rails.root}/lib/data_cycle/update_cycle_alert_generator"
require "#{Rails.root}/lib/student_greeting_checker"

# Executes all the steps of 'update_constantly' data import task
class ShortUpdate
  include BatchUpdateLogging
  include CacheUpdater
  include UpdateCycleAlertGenerator

  def initialize
    setup_logger
    set_courses_to_update
    return if updates_paused?
    return if conflicting_updates_running?

    run_update_with_pid_files(:constant)
  end

  private

  def set_courses_to_update
    @courses = Course.ready_for_short_update.to_a
    log_message "Ready to update #{@courses.count} courses"
  end

  def run_update
    log_start_of_update 'Short update tasks are beginning.'
    update_revisions_and_articles
    update_new_article_views unless ENV['no_views'] == 'true'
    update_new_article_ratings
    import_uploads_for_needs_update_editathons
    update_categories_for_needs_update_editathons
    update_all_caches # from CacheUpdater
    generate_alerts # from UpdateCycleAlertGenerator
    log_end_of_update 'Short update finished.'
  # rubocop:disable Lint/RescueException
  rescue Exception => e
    log_end_of_update 'Short update failed.'
    raise e
  end
  # rubocop:enable Lint/RescueException

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

  # Uploads are normally imported only during the DailyUpdate for current courses.
  # However, courses from the past that were marked for update need to have their
  # uploads imported during the ConstantUpdate before their :needs_update flags
  # are removed.
  def import_uploads_for_needs_update_editathons
    log_message 'Backfilling Commons uploads for editathons'
    UploadImporter.import_all_uploads User.joins(:courses).where(courses: { type: 'Editathon',
                                                                            needs_update: true })
                                          .distinct
    UploadImporter.update_usage_count_by_course Course.where(type: 'Editathon')
                                                      .where(needs_update: true)
  end

  # As with commons uploads, this is done normally in DailyUpdate
  def update_categories_for_needs_update_editathons
    Category.refresh_categories_for(Course.where(type: 'Editathon')
                                          .where(needs_update: true))
  end

  #################################
  # Logging and process managment #
  #################################

  def conflicting_updates_running?
    return true if update_running?(:short)
    return true if update_running?(:daily)
    return true if update_running?(:constant)
    return true if update_waiting_to_run?
    false
  end
end
