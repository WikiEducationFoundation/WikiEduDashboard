# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/data_cycle/batch_update_logging"
require_dependency "#{Rails.root}/app/workers/training_base_worker"
# Executes all the steps of 'update_views' data import task
class TrainingUpdate
  attr_reader :result

  include BatchUpdateLogging

  def initialize(module_slug:)
    @module_slug = module_slug

    setup_logger

    if CheckTrainingUpdateStatus.job_running?
      @result = 'Another training update process is already in progress. Try again later.'
      return
    end
    run_update_with_pid_files(:training)
  end

  private

  def run_update
    log_start_of_update "Training update task is beginning. Module: #{@module_slug}"
    update_training_content
    @result = CheckTrainingUpdateStatus.schedule_check
    log_end_of_update 'Training update finished.'

  # rubocop:disable Lint/RescueException
  rescue Exception => e
    log_end_of_update 'Training update failed.'
    raise e
  end
  # rubocop:enable Lint/RescueException

  def update_training_content
    if @module_slug == 'all'
      TrainingBase.update_status_to_scheduled
      TrainingBaseWorker.update_training_content
    else
      TrainingBase.update_status_to_scheduled(slug: @module_slug)
      TrainingBaseWorker.update_training_content(slug: @module_slug)
    end
  end
end
