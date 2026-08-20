# frozen_string_literal: true
require_dependency "#{Rails.root}/lib/analytics/report_csv_store"

class CsvCleanupWorker
  include Sidekiq::Worker

  def perform(filename)
    ReportCsvStore.delete filename
  end
end
