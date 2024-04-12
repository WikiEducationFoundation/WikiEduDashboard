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

    if CheckTrainingUpdateStatus.job_running?
      puts 'STEP - Another training update process is already in progress. Try again later.'
      @result = 'Another training update process is already in progress. Try again later.'
      return
    end
    puts 'STEP - Training update process started.'
    run_update_with_pid_files(:training)
  end

  private

  def run_update
    log_start_of_update "Training update task is beginning. Module: #{@module_slug}"
    if Features.wiki_trainings?
      update_training_content_from_wiki
    else
      update_training_content_from_yaml
    end
    @result = CheckTrainingUpdateStatus.schedule_check
    log_end_of_update 'Training update finished.'

  # rubocop:disable Lint/RescueException
  rescue Exception => e
    log_end_of_update 'Training update failed.'
    raise e
  end
  # rubocop:enable Lint/RescueException

  def update_training_content_from_wiki
    if @module_slug == 'all'
      TrainingBase.update_status_to_scheduled
      TrainingBaseWorker.update_training_content
    else
      TrainingBase.update_status_to_scheduled(slug: @module_slug)
      TrainingBaseWorker.update_training_content(slug: @module_slug)
    end
  end

  def update_training_content_from_yaml
    TrainingLibrary.load_from_yaml
    TrainingModule.load_from_yaml
    if @module_slug == 'all'
      TrainingModule.all.each { |tm| TrainingSlide.load_from_yaml(slug_list: tm.slide_slugs) }
    else
      training_module = TrainingModule.find_by(slug:)
      raise ModuleNotFound, "No module #{slug} found!" unless training_module
      TrainingSlide.load(slug_list: training_module.slide_slugs)
    end
  end
end
