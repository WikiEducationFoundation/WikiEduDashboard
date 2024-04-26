# frozen_string_literal: true

class TrainingBaseWorker
  include Sidekiq::Worker
  sidekiq_options lock: :until_executed
  sidekiq_options retry: false

  def self.queue_update_process(slug)
    perform_async(slug)
  end

  # Called during manual :training_reload action.
  # This should regenerate all training content from yml files and/or wiki.
  def perform_load_all
    if Features.wiki_trainings?
      TrainingModule.all.each { |tm| TrainingSlide.load_async(slug_list: tm.slide_slugs) }
    else
      TrainingSlide.load_async
    end
  end

  # This reloads all the library and module content, but only updates the slides
  # for the module with the given slug.
  def perform_reload_module(slug)
    # Reload the requested module's slides
    training_module = TrainingModule.find_by(slug:)
    if training_module
      TrainingSlide.load_async(slug_list: training_module.slide_slugs)
    else
      TrainingBase.finish_content_class_update_process(TrainingSlide)
      raise TrainingModule::ModuleNotFound, "No module #{slug} found!"
    end
  end

  def perform(slug)
    # First reload the libraries and modules so we have the new list of slugs
    # and can load slides for brand-new modules.
    TrainingLibrary.load_async
    TrainingBase.finish_content_class_update_process(TrainingLibrary)
    TrainingModule.load_async
    TrainingBase.finish_content_class_update_process(TrainingModule)
    if slug['slug'] == 'all'
      perform_load_all
    else
      perform_reload_module(slug)
    end
    TrainingBase.finish_content_class_update_process(TrainingSlide)
  rescue TrainingModule::ModuleNotFound => e
    TrainingBase.update_error(e.message, TrainingModule)
  end
end