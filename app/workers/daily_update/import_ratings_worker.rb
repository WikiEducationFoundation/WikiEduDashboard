# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/importers/rating_importer"

class ImportRatingsWorker
  include Sidekiq::Worker
  sidekiq_options lock: :until_executed

  def perform
    RatingImporter.update_all_ratings
  end
end
