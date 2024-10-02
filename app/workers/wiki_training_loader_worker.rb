# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/training/wiki_training_loader"

class WikiTrainingLoaderWorker
  include Sidekiq::Worker
  sidekiq_options lock: :until_executed
  sidekiq_options retry: false

  def start_content_class_update_process(content_class, slug_list)
    perform(content_class, slug_list)
  end

  def perform(content_class, slug_list)
    WikiTrainingLoader.new(content_class:, slug_list:, sidekiq_job: true)
  end
end
