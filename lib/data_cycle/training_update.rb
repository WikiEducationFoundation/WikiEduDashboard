# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/data_cycle/batch_update_logging"
require_dependency "#{Rails.root}/app/workers/training_base_worker"
require_dependency "#{Rails.root}/lib/training/training_base"

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
    start_update_process
    @result = 'Success!'
    log_end_of_update 'Training update finished.'

  # rubocop:disable Lint/RescueException
  rescue Exception => e
    log_end_of_update 'Training update failed.'
    raise e
  ensure
    delete_pid_file(:training)
  end
  # rubocop:enable Lint/RescueException

  def start_update_process
    if Features.wiki_trainings?
      update_wiki_training_content
    else
      update_yaml_training_content
    end
  end

  def update_wiki_training_content
    TrainingBase.new.update_process_state(1)
    TrainingBaseWorker.queue_update_process(slug: @module_slug)

    sleep 60 while update_running?(:training)

    if TrainingBase.error_in_update_process
      error_message = TrainingBase.update_process_error_message
      raise e, error_message
    end
  end

  def update_yaml_training_content
    TrainingLibrary.load
    TrainingModule.load
    if @module_slug == 'all'
      TrainingModule.all.each { |tm| TrainingSlide.load(slug_list: tm.slide_slugs) }
    else
      training_module = TrainingModule.find_by(slug:)
      raise ModuleNotFound, "No module #{slug} found!" unless training_module
      TrainingSlide.load(slug_list: training_module.slide_slugs)
    end
  end
end
