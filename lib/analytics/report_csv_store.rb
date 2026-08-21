# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/analytics/local_report_csv_store"
require_dependency "#{Rails.root}/lib/analytics/s3_report_csv_store"

#= Stores the CSV report exports built by ReportCsvWorker, and provides the urls
#= that users are sent to in order to download them.
# Deployments that set report_csv_bucket keep the reports in S3-compatible object
# storage, so that the reports can be generated on a different server than the one
# that serves them. Otherwise, they are kept on the local filesystem.
class ReportCsvStore
  def self.local
    LocalReportCsvStore.new
  end

  def self.s3
    S3ReportCsvStore.new
  end

  def self.exists?(filename)
    store.exists?(filename)
  end

  def self.write(filename, data)
    store.write(filename, data)
  end

  def self.url_for(filename)
    store.url_for(filename)
  end

  def self.delete(filename)
    store.delete(filename)
  end

  def self.store
    @store ||= ENV['report_csv_bucket'].present? ? s3 : local
  end

  private_class_method :store
end
