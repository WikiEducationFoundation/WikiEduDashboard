# frozen_string_literal: true

require "#{Rails.root}/lib/data_cycle/batch_update_logging"
require "#{Rails.root}/lib/importers/view_importer"

# Executes all the steps of 'update_views' data import task
class ViewsUpdate
  include BatchUpdateLogging

  def initialize
    setup_logger
    return if updates_paused?
    return if update_running?(:views)

    run_update_with_pid_files(:views)
  end

  private

  def run_update
    log_start_of_update 'Views update task is beginning.'
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
end
