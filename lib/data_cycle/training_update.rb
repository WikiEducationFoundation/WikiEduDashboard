# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/data_cycle/batch_update_logging"
require_dependency "#{Rails.root}/lib/training_module"

# Executes all the steps of 'update_views' data import task
class TrainingUpdate
  attr_reader :result
  include BatchUpdateLogging

  def initialize(module_slug:)
    @module_slug = module_slug

    setup_logger
    if update_running?(:training)
      @result = 'Another training update process is already in progress. Try again later.'
      return
    end
    run_update_with_pid_files(:training)
  end

  private

  def run_update
    log_start_of_update "Training update task is beginning. Module: #{@module_slug}"
    update_training_content
    @result = 'Success!'
    log_end_of_update 'Training update finished.'
  # rubocop:disable Lint/RescueException
  rescue Exception => e
    log_end_of_update 'Training update failed.'
    raise e
  end
  # rubocop:enable Lint/RescueException

  def update_training_content
    if @module_slug == 'all'
      TrainingModule.load_all
    else
      TrainingModule.reload_module slug: @module_slug
    end
  end
end
