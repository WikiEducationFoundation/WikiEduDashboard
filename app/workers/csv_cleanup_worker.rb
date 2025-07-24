# frozen_string_literal: true

class CsvCleanupWorker
  include Sidekiq::Worker

  def perform(filename)
    File.delete "public#{ReportsController::CSV_PATH}/#{filename}"
  end
end
