# frozen_string_literal: true
require_dependency "#{Rails.root}/lib/analytics/report_csv_store"

class CsvCleanupWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'report_csv'

  # Deletes without checking exists? first: the S3 store's exists? answers
  # false on any S3 error, which would skip the delete for good. An S3 error
  # here raises instead, so Sidekiq retries it; deleting a missing S3 object
  # succeeds.
  def perform(filename)
    ReportCsvStore.delete filename
  rescue Errno::ENOENT, Aws::S3::Errors::NoSuchKey, Aws::S3::Errors::NotFound
    # Cleanups scheduled before report names changed can't find their files.
    # S3 normally reports success for a missing key, but not every gateway does.
    nil
  end
end
