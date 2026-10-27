# frozen_string_literal: true
require_dependency "#{Rails.root}/lib/analytics/report_csv_store"

class CsvCleanupWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'report_csv'

  # Cleanups scheduled before report names changed can't find their files.
  def perform(filename)
    ReportCsvStore.delete filename if ReportCsvStore.exists?(filename)
  end
end
