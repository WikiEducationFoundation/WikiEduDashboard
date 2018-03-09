# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/data_cycle/batch_update_logging"
require_dependency "#{Rails.root}/app/services/update_course_revisions"

# Executes all the steps of 'update_constantly' data import task
class ShortUpdate
  include BatchUpdateLogging

  def initialize
    setup_logger
    log_message "Ready to update #{Course.ready_for_short_update.count} courses"
    return if updates_paused?
    return if conflicting_updates_running?

    run_update_with_pid_files(:short)
  end

  private

  def run_update
    log_start_of_update 'Short update tasks are beginning.'
    update_course_revisions
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

  def update_course_revisions
    log_message 'Importing revisions and articles for soon-to-end courses'
    Course.ready_for_short_update.each { |course| UpdateCourseRevisions.new(course) }
  end

  def conflicting_updates_running?
    return true if update_running?(:short)
    false
  end
end
