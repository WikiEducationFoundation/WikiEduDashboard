# frozen_string_literal: true

class CsvCleanupWorker
  include Sidekiq::Worker

  def perform(filename)
    File.delete "public#{CampaignsController::CSV_PATH}/#{filename}"
  end
end
