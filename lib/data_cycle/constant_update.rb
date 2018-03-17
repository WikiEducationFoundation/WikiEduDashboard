# frozen_string_literal: true

# Adding these model dependencies explicitly is intended to avoid intermittent
# NameError and ciruclar dependency errors
require_dependency "#{Rails.root}/app/models/article"
require_dependency "#{Rails.root}/app/models/revision"
require_dependency "#{Rails.root}/app/models/course"
require_dependency "#{Rails.root}/app/models/week"
require_dependency "#{Rails.root}/app/models/block"

require_dependency "#{Rails.root}/lib/data_cycle/batch_update_logging"
require_dependency "#{Rails.root}/lib/course_revision_updater"
require_dependency "#{Rails.root}/lib/assignment_updater"
require_dependency "#{Rails.root}/lib/importers/revision_score_importer"
require_dependency "#{Rails.root}/lib/importers/plagiabot_importer"
require_dependency "#{Rails.root}/lib/importers/course_upload_importer"
require_dependency "#{Rails.root}/lib/importers/view_importer"
require_dependency "#{Rails.root}/lib/importers/rating_importer"
require_dependency "#{Rails.root}/lib/data_cycle/cache_updater"
require_dependency "#{Rails.root}/lib/data_cycle/update_cycle_alert_generator"
require_dependency "#{Rails.root}/lib/student_greeting_checker"

# Executes all the steps of 'update_constantly' data import task
class ConstantUpdate
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
    @courses = Course.ready_for_update.to_a
    log_message "Ready to update #{@courses.count} courses"
  end

  def run_update
    log_start_of_update 'Constant update tasks are beginning.'
    update_revisions_and_articles
    update_new_article_views unless ENV['no_views'] == 'true'
    update_new_article_ratings
    import_uploads_for_needs_update_courses
    update_categories_for_needs_update_courses
    update_all_caches # from CacheUpdater
    remove_needs_update_flags
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

  def import_uploads_for_needs_update_courses
    log_message 'Updating Commons uploads for current courses'
    CourseUploadImporter.update_courses @courses
  end

  # This is done normally in DailyUpdate for current courses.
  # However, courses from the past that were marked for update need to have it
  # done before their :needs_update flags are removed.
  def update_categories_for_needs_update_courses
    Category.refresh_categories_for(Course.where(needs_update: true))
  end

  #################################
  # Logging and process managment #
  #################################

  def remove_needs_update_flags
    @courses.select(&:needs_update).each do |course|
      course.update_attribute(:needs_update, false)
    end
  end

  def conflicting_updates_running?
    return true if update_running?(:daily)
    return true if update_running?(:constant)
    return true if update_waiting_to_run?
    false
  end
end
