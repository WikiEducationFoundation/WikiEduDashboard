# frozen_string_literal: true
require_dependency "#{Rails.root}/lib/training/wiki_training_loader"

class WikiTrainingLoaderWorker
  include Sidekiq::Worker
  # sidekiq_options lock: :until_executed

  def perform(content_class, slug_list)
    WikiTrainingLoader.load_content(content_class, slug_list)
  end   
end