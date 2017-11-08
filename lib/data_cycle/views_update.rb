# frozen_string_literal: true

require "#{Rails.root}/lib/data_cycle/batch_update_logging"
require "#{Rails.root}/lib/importers/view_importer"

# Executes all the steps of 'update_views' data import task
class ViewsUpdate
  include BatchUpdateLogging

  def initialize
    setup_logger
    return if updates_paused?
    return if views_update_running?

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
    update_article_views unless ENV['no_views'] == 'true'
    log_end_of_update 'Views update finished.'
  # rubocop:disable Lint/RescueException
  rescue Exception => e
    log_end_of_update 'Views update failed.'
    raise e
  end
  # rubocop:enable Lint/RescueException

  def update_article_views
    log_message 'Updating article views'
    ViewImporter.update_all_views(true)
  end

  #################################
  # Logging and process managment #
  #################################

  def create_pid_file
    File.open(VIEWS_UPDATE_PID_FILE, 'w') { |f| f.puts Process.pid }
  end

  def delete_pid_file
    File.delete VIEWS_UPDATE_PID_FILE if File.exist? VIEWS_UPDATE_PID_FILE
  end

  def log_start_of_update
    @start_time = Time.zone.now
    Rails.logger.info 'Views update task is beginning.'
  end
end
