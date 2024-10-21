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
    puts "TrainingUpdate: #{@module_slug}"
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
    wait_for_update_to_finish
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

  def wait_for_update_to_finish
    puts 'Waiting for update process to finish...'
    loop do
      puts 'Checking for updates...'
      break unless TrainingBase.update_running?
      sleep 60
    end

    if TrainingBase.error_in_update_process
      error_message = TrainingBase.update_process_error_message
      puts 'caught error messages'
      puts error_message
      TrainingBase.new.clear_error_messages
      TrainingBase.new.update_process_state(0)
      raise error_message
    end
    @result = 'Success!'
  end

  def update_wiki_training_content
    puts 'Updating wiki training content...'
    TrainingBase.new.update_process_state(1)
    puts 'Queuing update process...'
    TrainingBaseWorker.queue_update_process(slug: @module_slug)
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
