# frozen_string_literal: true

class TrainingBaseWorker
  include Sidekiq::Worker
  sidekiq_options lock: :until_executed

  def self.update_training_content(slug: 'all')
    perform_async(slug)
  end

  # Called during manual :training_reload action.
  # This should regenerate all training content from yml files and/or wiki.
  def perform_load_all
    if Features.wiki_trainings?
      TrainingModule.all.each { |tm| TrainingSlide.load(slug_list: tm.slide_slugs) }
    else
      TrainingSlide.load
    end
  end

  # This reloads all the library and module content, but only updates the slides
  # for the module with the given slug.
  def perform_reload_module(slug)
    # Reload the requested module's slides
    training_module = TrainingModule.find_by(slug:)
    raise ModuleNotFound, "No module #{slug} found!" unless training_module
    TrainingSlide.load(slug_list: training_module.slide_slugs)
  end

  def perform(slug)
    # First reload the libraries and modules so we have the new list of slugs
    # and can load slides for brand-new modules.
    TrainingLibrary.load
    TrainingModule.load
    if slug == 'all'
      perform_load_all
    else
      perform_reload_module(slug)
    end
    # rescue TrainingModule::ModuleNotFound => e
  end
end
