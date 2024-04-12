# frozen_string_literal: true
require_dependency "#{Rails.root}/lib/training/wiki_training_loader"

class WikiTrainingLoaderWorker
  include Sidekiq::Worker
  sidekiq_options lock: :until_executed

  def perform(content_class, slug_list)
    WikiTrainingLoader.load_content(content_class, slug_list)
  rescue TrainingBase::DuplicateSlugError => e
    TrainingBase.update_error(e['message'], e['content_class'], e['slug'])
  rescue WikiTrainingLoader::InvalidWikiContentError,
         WikiTrainingLoader::NoMatchingWikiPagesFound => e
    TrainingBase.update_error_content_class(e['message'], e['content_class'])
  end
end
